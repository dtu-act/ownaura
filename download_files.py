import urllib.request
import os
import tarfile

# change cwd to `data`
abspath = os.path.abspath(__file__)
dname = os.path.dirname(abspath)
os.chdir(dname)

files = ['odeon_rooms.tar.gz', 'vr_unity_projects.tar.gz']

# download files
baseurl = 'https://github.com/fhchl/quant-comp-ls-mod-ica22/releases/download/reproduces-results' 
urls = [baseurl+'/'+f for f in files]
for url in urls:
  filename = url.split('/')[-1]
  print("downloading", filename, "...")
  urllib.request.urlretrieve(url, filename)
print("Done downloading.")

# extract them
def extract(path, dest):
  with tarfile.open(path, 'r') as tar:
    tar.extractall(dest)

for f in files:
  print("extracting", f, "...")
  extract(f, '.')
print("Done extracting.")
