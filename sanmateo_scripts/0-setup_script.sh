# Grant permissions to your user
usermod -aG sudo <username>

# FROM postgresql.org/download/linux/ubuntu/
# Create the file repository configuration:
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Import the repository signing key:
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Update the package lists:
sudo apt-get update

# Install the latest version of PostgreSQL.
# If you want a specific version, use 'postgresql-12' or similar instead of 'postgresql':
sudo apt-get -y install postgresql-14 postgresql-14-postgis-3
sudo apt-get -y install postgresql-plpython3-14

# Start PostgreSQL.
sudo service postgresql start

# FROM https://mothergeo-py.readthedocs.io/en/latest/development/how-to/gdal-ubuntu-pkg.html
# Install GDAL
sudo add-apt-repository ppa:ubuntugis/ppa
sudo apt-get update
sudo apt-get install gdal-bin

# Setup Postgres User and DB
# Replace with your DB, username, desired password
sudo -u postgres psql -c "
	create database sanmateo; 
	create user chlowrie;
	alter user chlowrie with encrypted password 'roqfuf-0xidti';
	grant all privileges on database sanmateo to chlowrie;
	alter user chlowrie with superuser;

"

