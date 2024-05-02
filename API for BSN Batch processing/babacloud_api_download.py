# BABACloud Python API download script
# For help type python babacloud_api_download.py --help
# OR read the Readme.txt file
# Author: Manu Airaksinen, airaksinen.manu@gmail.com

import requests
import json
import os
import time
import argparse

import credentials  # Required: credentials.py with user=username; pw=password in same directory

url_subject = "https://babacloud.fi/apiv1/subject/"
url_rawfile = "https://babacloud.fi/apiv1/rawfile/"
url_resultfile = "https://babacloud.fi/apiv1/resultfile/"
url_analysisrun = "https://babacloud.fi/apiv1/analysisrun/"

LINE_UP = '\033[1A'
LINE_CLEAR = '\x1b[2K'


def api_get(url, id):
    response = requests.get(url + str(id) + '/', auth=(credentials.user,
                                                       credentials.pw))
    return json.loads(response.content)


def filter_result(result_list, filter_dict=None):
    output_list = []
    ii = 1
    for item in result_list:
        if filter_dict is None:
            output_list.append(item)
        else:
            append_output = True
            for dict_item in filter_dict.items():
                key = dict_item[0]
                val = dict_item[1]

                if type(val) is list:
                    found = False
                    for valitem in val:
                        if item[key] == valitem:
                            found = True

                    if not found:
                        append_output = False
                else:
                    if item[key] != val:
                        append_output = False

            if append_output:
                item['item'] = ii
                output_list.append(item)
                ii += 1

    return output_list


def api_get_all_rawfile(url, filter_dict=None):
    response = requests.get(url, auth=(credentials.user,
                                       credentials.pw))
    response_js = json.loads(response.content)
    output_list = []

    if filter_dict is None:
        output_list = response_js

    else:
        for item in response_js:
            append_output = True
            for dict_item in filter_dict.items():
                key = dict_item[0]
                val = dict_item[1]
                if type(val) is list:
                    found = False
                    for valitem in val:
                        if item[key] == valitem:
                            found = True

                    if not found:
                        append_output = False
                else:
                    if item[key] != val:
                        append_output = False

            if append_output:
                output_list.append(item)

    return output_list


def api_get_all(url, filter_dict=None):
    response = requests.get(url, auth=(credentials.user,
                                       credentials.pw))
    response_js = json.loads(response.content)
    output_list = []
    while True:
        for i, item in enumerate(response_js['results']):
            if filter_dict is None:
                output_list.append(item)

            else:
                append_output = True
                for dict_item in filter_dict.items():
                    key = dict_item[0]
                    val = dict_item[1]
                    if type(val) is list:
                        found = False
                        for valitem in val:
                            if item[key] == valitem:
                                found = True

                        if not found:
                            append_output = False
                    else:
                        if item[key] != val:
                            append_output = False

                if append_output:
                    output_list.append(item)

        if response_js['next'] is None:
            break

        response = requests.get(response_js['next'], auth=(credentials.user,
                                                           credentials.pw))
        response_js = json.loads(response.content)

    return output_list


def api_download_file(file_url, target_dir='./', replace_target=False):
    fname = (file_url.split('?')[0]).split('/')[-1]
    fname = os.path.join(target_dir, fname)
    print(f'   Saving to {fname}')
    print('')

    BLOCK = 1024 * 1024

    try:
        r = requests.get(file_url, stream=True)
        total_length = int(r.headers.get('content-length'))
        if os.path.isfile(fname) and not replace_target:
            size_file = os.path.getsize(fname)
            size_ratio = size_file / total_length
            if size_ratio > 0.9:
                print('File already found. Skipping download (replace_target = False).')
                return fname

        with open(fname, 'wb') as f:
            t0 = time.time()
            time_start = t0
            progress_bytes = 0
            for chunk in r.iter_content(chunk_size=BLOCK):
                if chunk:
                    progress_bytes += len(chunk)
                    # Calculate the speed
                    t1 = time.time()
                    t = t1 - t0
                    speed = round((len(chunk) / (1024 * 1024)) / t, 2)

                    # Write the block to the file.
                    f.write(chunk)
                    f.flush()

                    # Write stats
                    # done = int(50 * (progress_bytes / total_length) )
                    print(LINE_UP, end=LINE_CLEAR)
                    print(f'   ({progress_bytes/(1024*1024):0.2f} of {total_length/(1024*1024):0.2f} MB) (elapsed: {t1-time_start:0.1f} s) ({speed:0.1f} MBps)')

                    t0 = time.time()

            time_tot = time.time() - time_start
            print(f'\nFinished in {time_tot:.2f} seconds. Average speed {total_length/(1024*1024)/time_tot:.2f} MBps.')

    except Exception as e:
        print("Error: ", e, 0)

    return fname


def save_list(filelist, filename='filelist.csv'):
    # Add all keys to filelist
    keys = []
    for item in filelist:
        keys.extend(item.keys())
    keys = list(dict.fromkeys(keys))
    empty = dict.fromkeys(keys, None)
    filelist = [dict(empty, **d) for d in filelist]

    # Write output file
    with open(filename, 'w') as csvfile:
        keys_str = [str(ii).replace(',', ';') for ii in keys]
        csvfile.write(','.join(keys_str))
        csvfile.write('\n')

        for item in filelist:
            item_vals = item.values()
            item_vals_str = [str(ii).replace(',', ';').replace('\n', '') for ii in item_vals]
            csvfile.write(','.join(item_vals_str))
            csvfile.write('\n')
    return


def parse_labels(label_list, target_dict={}):
    for item in label_list:
        target_dict.update({item['name'].lower(): item['value']})

    return target_dict


def combine_lists(rawfiles, subjects, analyses, results):
    output_list = []
    ii = 1
    for iraw in rawfiles:
        modality = None
        analysis_id = None
        error = None
        result_id = None
        analysis_success = False
        result_file_url = None

        basename = iraw['raw_file']
        if basename is None:
            continue

        basename = (basename.split('?')[0]).split('/')[-1]
        raw_id = iraw['id']
        subject_id = iraw['subject']
        org_id = iraw['organization']
        modality = iraw['modality']
        raw_file_url = iraw['raw_file']
        labels = iraw['rawfile_label']

        analysis_found = False
        for iana in analyses:
            if raw_id == iana['source_file']:
                analysis_found = True
                # analysis_modality = iana['analysis']
                analysis_id = iana['id']
                error = iana['error_message']
                if error is not None:
                    error = error.replace(',', ';')
                    error = error.replace('\n', ' ')
                result_id = iana['result_file']
                if result_id is not None:
                    analysis_success = True

                break

        if not analysis_found:
            for ires in results:
                if raw_id == ires['original_file']:
                    analysis_success = True
                    result_id = ires['id']
                    break

        for ires in results:
            if raw_id == ires['original_file']:
                result_file_url = ires['result_file']
                break

        # Search from subjects:
        for isub in subjects:
            subject_name = None
            if subject_id == isub['id']:
                subject_name = isub['identifier']
                break

        item_dict = {'item': ii, 'id': subject_name, 'filename': basename, 'organization': org_id,
                     'modality': modality, 'analyzed': analysis_success,
                     'error_message': error, 'raw_id': raw_id, 'subject_id': subject_id,
                     'analysis_id': analysis_id, 'result_id': result_id,
                     'raw_file': raw_file_url, 'result_file': result_file_url}

        if len(labels) > 0:
            item_dict = parse_labels(labels, item_dict)
        output_list.append(item_dict)
        ii += 1

    return output_list


def download_rawfiles(filelist, target_dir='./', replace=False):
    print(f'Downloading rawfiles from {len(filelist)} items.')
    for i, item in enumerate(filelist):
        print(f'{i+1} / {len(filelist)} ({100*(i+1)/len(filelist):.1f}%)')
        api_download_file(item['raw_file'], target_dir, replace_target=replace)

    return


def download_resultfiles(filelist, target_dir='./', replace=False):
    print(f'Downloading results from {len(filelist)} items.')
    for i, item in enumerate(filelist):
        print(f'{i+1} / {len(filelist)} ({100*(i+1)/len(filelist):.1f}%)')
        if item['result_id'] is not None:
            api_download_file(item['result_file'], target_dir,
                              replace_target=replace)

    return


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-o', '--output_dir', type=str, default='./', help='output directory')
    parser.add_argument('--listonly', help='Save a list only.', action='store_true')
    parser.add_argument('--replace', help='Replace existing files.', action='store_true')
    parser.add_argument('-m', '--modality', type=str, default=None, help='Recording modality')
    input_args = parser.parse_args()

    if input_args.output_dir is not None:
        os.makedirs(input_args.output_dir, exist_ok=True)

    # Get database items
    rawfile_list = api_get_all_rawfile(url_rawfile)
    subject_list = api_get_all(url_subject)
    resultfile_list = api_get_all(url_resultfile)
    analysisrun_list = api_get_all(url_analysisrun)

    # Combine information
    combined_list = combine_lists(rawfile_list, subject_list, analysisrun_list, resultfile_list)

    # Filter list by desired parameters
    if input_args.modality is not None:
        filter_dict = {'modality': input_args.modality,
                       'analyzed': True}
        list_filtered = filter_result(combined_list, filter_dict)
    else:
        list_filtered = combined_list

    # Save list to output directory
    save_list(list_filtered, os.path.join(input_args.output_dir, 'list_filtered.csv'))

    # Download rawfiles and resultfiles if desired
    if not input_args.listonly:
        download_rawfiles(list_filtered, 'output_data/', replace=input_args.replace)
        download_resultfiles(list_filtered, 'output_data/', replace=input_args.replace)

    print('Done.')
