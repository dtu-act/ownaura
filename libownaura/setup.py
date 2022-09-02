from setuptools import setup

# Package meta-data.
NAME = "libownaura"
EMAIL = "franz.heuchel@gmail.com"
AUTHOR = "Franz M. Heuchel"
REQUIRES_PYTHON = ">=3.6.0"
REQUIRED = ["numpy","python-sounddevice","scipy","matplotlib","response"]

setup(
    name=NAME,
    author=AUTHOR,
    author_email=EMAIL,
    python_requires=REQUIRES_PYTHON,
    packages=["libownaura"],
    include_package_data=True,
)