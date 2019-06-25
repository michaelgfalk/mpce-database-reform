from setuptools import setup, find_namespace_packages

# read the contents of your README file
from os import path
this_directory = path.abspath(path.dirname(__file__))
with open(path.join(this_directory, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()

setup(
    name = 'mpceDatabaseReform',
    version = '1.0',
    packages = find_namespace_packages(include = ['mpcereform.*']),
    author = "Michael Falk",
    description = "Reforms and repopulates the new MPCE database from the 'manuscripts' version.",
    license = "MIT",
    keywords = "MariaDB enlightenment french-book-trade",
    url="http://fbtee.uws.edu.au/mpce/",
    entry_points={
        'console_scripts': ['reform-db=mpcereform.reform:main']
    },
    install_requires=[
        'openpyxl',
        'mysql-connector'
    ]
)
