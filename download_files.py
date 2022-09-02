import urllib.request
import os
import tarfile

# change cwd to `data`
abspath = os.path.abspath(__file__)
dname = os.path.dirname(abspath)
os.chdir(dname)

files = ['odeon_rooms.tar.gz', 'vr_unity_project.tar.gz', 'filters.tar.gz']

print("This can take a while.")
# download files
baseurl = 'https://github.com/dtu-act/ownaura/releases/download/v0.1.0/' 
for f in files:
  print("downloading", f, "...")
  urllib.request.urlretrieve(baseurl+f, f)
print("Done downloading.")

# extract them
def extract(path, dest):
  with tarfile.open(path, 'r') as tar:
    tar.extractall(dest)

for f in files:
  print("extracting", f, "...")
  extract(f, '.')
print("Done extracting.")
