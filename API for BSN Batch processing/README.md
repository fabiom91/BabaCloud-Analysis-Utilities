#### README for BABACloud Python API ####
Author: Manu Airaksinen
email: airaksinen.manu@gmail.com

#### Required Python packages: ####
python (tested w/ v3.8.15)

requests (tested w/ v2.28.1)             
   -- pip install requests
   -- conda install -c anaconda requests
requests-toolbelt (tested w/ v0.10.1)    
   -- pip install requests-toolbelt
   -- conda install -c conda-forge requests-toolbelt

#### Credentials: ####
REQUIRED: 
  credentials.py in the same folder with the API scripts with the following content:
    # Begin credentials.py
    user = 'username' # Your BABACloud username
    pw = 'password' # Your password
    # End credentials.py

#### Scripts: ####
babacloud_api_analysis.py
  Purpose:
    Upload recordings to Babacloud for analysis and retrieve generated analysis.
    Optionally delete uploaded & generated files. 
  Usage:
    python babacloud_api_analysis.py --help


babacloud_api_download.py
  Purpose:
    Download recordings and/or analysis files from BABAcloud 
  Usage:
    python babacloud_api_download.py --help



#### Example: ####
Run babyEEG analyses on EDF files stored in the "test" folder and save the analyses results in the "output" folder. 

python babacloud_api_analysis.py -o output -m babyeeg test