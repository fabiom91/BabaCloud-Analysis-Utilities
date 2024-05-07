# BABACloud Python API analysis script
# For help type python babacloud_api_analysis.py --help
# OR read the Readme.txt file
# Author: Manu Airaksinen, airaksinen.manu@gmail.com
# Editted: Saeed Montazeri, montazeri1369math@gmail.com

from requests_toolbelt import MultipartEncoder, MultipartEncoderMonitor
import requests
import json
import os
import time
import sys
import argparse

import credentials  # Required: credentials.py with user=username; pw=password in same directory

url_subject = "https://babacloud.fi/apiv1/subject/"
url_rawfile = "https://babacloud.fi/apiv1/rawfile/"
url_resultfile = "https://babacloud.fi/apiv1/resultfile/"
url_analysisrun = "https://babacloud.fi/apiv1/analysisrun/"

LINE_UP = '\033[1A'
LINE_CLEAR = '\x1b[2K'


def api_delete(url, id):
    if id == '':
        return False
    response = requests.delete(url + str(id) + '/', auth=(credentials.user,
                                                          credentials.pw))
    return response.ok


def api_get(url, id):
    response = requests.get(url + str(id) + '/', auth=(credentials.user,
                                                       credentials.pw))
    return json.loads(response.content)


def api_delete_all(id_raw, delete_subject=False):
    print(f'Deleting all data from ID: {id_raw}')
    id_subject = api_get(url_rawfile, id_raw)['rawfile']['subject']
    output = api_search(url_analysisrun, target_id=id_raw,
                        target_key='source_file',
                        output_keys=['id', 'result_file'])

    output_ok = []
    output_ok.append(api_delete(url_rawfile, id_raw))
    if output['found']:
        output_ok.append(api_delete(url_analysisrun, output['id']))

        if output['result_file'] is not None:
            output_ok.append(api_delete(url_resultfile, output['result_file']))

    if delete_subject:
        print(f'Deleting subject: {id_subject}')
        output_ok.append(api_delete(url_subject, id_subject))

    return output_ok


def api_search(url, target_id, target_key, output_keys=None):
    try:
        response = requests.get(url, auth=(credentials.user, credentials.pw))
    except requests.exceptions.ConnectionError as err:
        print(f'Warning: {err}')
        return {'found': False}

    response_js = json.loads(response.content)
    output = {}
    found = False
    while True:
        for i, item in enumerate(response_js['results']):
            target_key_val = item[target_key]
            if target_id == target_key_val:
                if output_keys is not None:
                    for key in output_keys:
                        output.update({key: item[key]})
                else:
                    output = response_js

                found = True
                break

        if found:
            break

        if response_js['next'] is None:
            print(f'   {target_id} not found in API: {url}')
            break

        response = requests.get(response_js['next'], auth=(credentials.user,
                                                           credentials.pw))
        response_js = json.loads(response.content)

    output.update({'found': found})
    return output


def api_search_rawfile(fname, target_subject):
    target_bname = os.path.basename(fname)
    response = requests.get(url_rawfile, auth=(credentials.user,
                                               credentials.pw))
    response_js = json.loads(response.content)

    found = False
    id = None

    for item in response_js:
        filename = item['raw_file']
        sub_id = item['subject']
        if filename is not None:
            filename = (filename.split('?')[0]).split('/')[-1]

        id = item['id']
        if target_bname == filename and target_subject == sub_id:
            found = True
            break

    if found:
        print(f'   {filename} already found in: {url_rawfile}')

    return found, id


def api_create_subject(url, target_id):
    print(f'   Creating new ID: {target_id}')
    m = MultipartEncoder(fields={'identifier': target_id})

    response = requests.post(url, data=m,
                             headers={'Content-Type': m.content_type},
                             auth=(credentials.user, credentials.pw))

    return response.ok


def get_subject_id_num(url, target_id):
    output = api_search(url, target_id, target_key='identifier',
                        output_keys=['id', 'identifier', 'organization'])

    # If not found, create new Subject:
    if not output['found']:
        create_ok = api_create_subject(url, target_id)
        if not create_ok:
            sys.exit(f'   Error: Unable to create subject through API: {target_id}')

        output = api_search(url, target_id, target_key='identifier',
                            output_keys=['id', 'identifier', 'organization'])

    return output['id'], output['organization']


def create_monitor_callback(m):
    encoder_len = m.len
    time_start = time.time()
    global _progress_prev
    global _time_prev
    _time_prev = time_start
    _progress_prev = 0
    print('')

    def callback(monitor):
        global _progress_prev
        global _time_prev
        progress = monitor.bytes_read
        # done = int(50 * progress/encoder_len)
        time_now = time.time()
        elapsed = time_now - time_start
        speed = ((progress - _progress_prev) / (1024 * 1024)) / (time_now - _time_prev)

        _progress_prev = progress
        _time_prev = time_now
        print(LINE_UP, end=LINE_CLEAR)
        print(f'   ({progress/(1024*1024):0.2f} of {encoder_len/(1024*1024):0.2f} MB) (elapsed: {elapsed:0.1f} s) ({speed:0.1f} MBps)')

    return callback


def api_upload_file(url, filename, id_num, org_num, modality, labels):
    basename = os.path.basename(filename)
    label_string = get_label_string(labels)
    if labels is not None:
        m = MultipartEncoder(
            fields={'name': 'raw_file',
                    'filename': basename,
                    'raw_file': (basename, open(filename, 'rb'), 'text/csv'),
                    'organization': str(org_num),
                    'modality': modality,
                    'subject': str(id_num),
                    'analyses': 'babyeeg',
                    'labels': label_string
                    }
        )
    else:
        m = MultipartEncoder(
            fields={'name': 'raw_file',
                    'filename': basename,
                    'raw_file': (basename, open(filename, 'rb'), 'text/csv'),
                    'organization': str(org_num),
                    'modality': modality,
                    'analyses': 'babyeeg',
                    'subject': str(id_num)
                    }
        )

    monitor_callback = create_monitor_callback(m)
    monitor = MultipartEncoderMonitor(m, monitor_callback)
    time_start = time.time()
    response = requests.post(url, data=monitor,
                             headers={'Content-Type': monitor.content_type},
                             auth=(credentials.user, credentials.pw))

    time_stop = time.time()

    response_js = json.loads(response.content)
    id_raw = response_js['id']
    print(f'\nUpload complete (id: {id_raw}) (elapsed time: {(time_stop-time_start):0.2f} s)')
    return id_raw


def api_download_result(result_url, target_dir='./'):
    response = requests.get(result_url, auth=(credentials.user,
                                              credentials.pw))
    target_filename = (result_url.split('?')[0]).split('/')[-1]
    target_filename = os.path.join(target_dir, target_filename)
    print('   Saving to ' + target_filename)
    open(target_filename, 'wb').write(response.content)

    return target_filename


def api_submit_rawfile(filename, target_id, modality='baby eeg', labels=None):
    print(f'Submitting file: {filename} to BABACloud ...')
    basename = os.path.basename(filename)
    # Get subject ID:
    print(f'   Searching subject: {target_id}')
    id_sub, org_num = get_subject_id_num(url_subject, target_id)

    # Check if rawfile already exists:
    rawfile_exists, id_raw = api_search_rawfile(basename, id_sub)

    if not rawfile_exists:
        print(f'   Uploading rawfile: {filename} to modality: {modality} ...')
        id_raw = api_upload_file(url_rawfile, filename, id_sub, org_num,
                                 modality=modality, labels=labels)

    return id_raw


def api_get_result(id_raw, target_dir='./'):

    output = api_search(url_analysisrun, target_id=id_raw,
                        target_key='source_file',
                        output_keys=['result_file', 'error_message'])

    fname = None

    if output['found']:
        if output['result_file'] is not None:
            id_result = output['result_file']
            output_result = api_get(url_resultfile, id_result)
            result_url = output_result['result_file']
            print(f'   Resultfile (id_raw: {id_raw}, id_result: {id_result}) found. Downloading ...')
            fname = api_download_result(result_url, target_dir=target_dir)
            print('Download successful.')
        else:
            error_msg = output['error_message']
            print(f'Analysis failed: {error_msg}')

    return output['found'], fname


def get_label_string(labels_dict):

    if labels_dict is None:
        return ''

    output_str = '['
    for key, val in zip(labels_dict.keys(), labels_dict.values()):
        output_str += '{"name": "' + str(key) + '", "value": "' + str(val) + '"},'

    output_str = output_str[:-1] + ']'

    return output_str


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('input', type=str, help='input directory OR file')
    parser.add_argument('-o', '--output_dir', type=str, default='./', help='output directory')
    parser.add_argument('--delete', help='Delete the data from BABAcloud after analysis.', action='store_true')
    parser.add_argument('-s', '--subject', type=str, default='Anonymous', help='Subject name')
    parser.add_argument('-m', '--modality', type=str, default='babyeeg', help='Recording modality')
    parser.add_argument('-t', '--timeout', type=int, default=None, help='Timeout time (minutes) for result waiting')
    input_args = parser.parse_args()

    if input_args.modality not in ('maiju', 'nappa', 'jumpsuit', 'babyeeg',
                                   'sleep pants', 'cogset', 'other'):
        sys.exit(f'Error: invalid modality: {input_args.modality}\nValid options: jumpsuit, maiju, babyeeg, nappa, cogset, other')

    if input_args.modality in ('jumpsuit', 'maiju'):
        input_args.modality = 'jumpsuit'
        modality_extensions = ('.csv', '.zip')
        analysis_available_for_modality = True
    elif input_args.modality == 'babyeeg':
        input_args.modality = 'eegpack'
        modality_extensions = ('.edf')
        analysis_available_for_modality = True
    elif input_args.modality in ('sleep pants', 'nappa'):
        input_args.modality = 'sleep pants'
        modality_extensions = ('.zip')
        analysis_available_for_modality = True
    else:
        modality_extensions = ('')
        analysis_available_for_modality = False

    if os.path.isdir(input_args.input):
        input_files = os.listdir(input_args.input)
        input_files = [os.path.join(input_args.input, file) for file in input_files
                       if (file[0] != '.') and file.endswith(modality_extensions)]

    else:
        if os.path.isfile(input_args.input) and (input_args.input[0] != '.') and input_args.input.endswith(modality_extensions):  # Interpret input as a file
            input_files = [input_args.input]

        else:
            sys.exit(f'Error: invalid input: {input_args.input}')

    os.makedirs(input_args.output_dir, exist_ok=True)

    target_id = input_args.subject
    
    upload_list = []
    delete_list = []
    elpased_timer = 0
    for i, filename in enumerate(input_files):
        # Upload rawfile:
        id_raw = api_submit_rawfile(filename, target_id,
                                    modality=input_args.modality)
        upload_list.append({'id_raw': id_raw, 'filename': filename})

    # Check for resultfile:
    if analysis_available_for_modality:
        print('Waiting for resultfiles')
        time_start = time.time()
        while len(upload_list) > 0:
            for i, item in enumerate(upload_list):
                analysis_found, result_fname = api_get_result(item['id_raw'],
                                                              input_args.output_dir)
                if analysis_found:
                    delete_list.append(upload_list.pop(i))
            if input_args.timeout:
                if time.time() > input_args.timeout * 60 + time_start: # - is changed to +
                    print('Timeout')
                    break

            if len(upload_list) > 0:
                time.sleep(10)
                elpased_timer = elpased_timer + 1
                print(f'Waiting time: {elpased_timer} minute(s)')

    if len(upload_list) > 0:
        print('Files without completed analysis: ')
        print(upload_list)
        print('')

    if input_args.delete:
        print(f'Deleting {len(delete_list)} recordings ...')
        for item in delete_list:
            fn = item['filename']
            id = item['id_raw']
            print(f'   Deleting {fn} (id={id}) ')
            api_delete_all(item['id_raw'])

        if len(upload_list) > 0:
            for item in upload_list:
                fn = item['filename']
                id = item['id_raw']
                print(f'   Deleting {fn} (id={id}) ')
                api_delete_all(item['id_raw'])

    print('Done.')
