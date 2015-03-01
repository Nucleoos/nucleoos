#!/bin/sh

sudo mkdir /opt/nucleoos
sudo chown $USER /opt/nucleoos
cd /opt/nucleoos

sudo apt-get install python-virtualenv python-pip python-dev unzip nginx libmemcached-dev memcached -y
# libs for pillow
sudo apt-get install libtiff5-dev libjpeg8-dev zlib1g-dev libfreetype6-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python-tk -y
# ubuntu 12.04 see https://github.com/python-pillow/Pillow/blob/master/docs/installation.rst
# sudo apt-get install libtiff4-dev libjpeg8-dev zlib1g-dev libfreetype6-dev liblcms2-dev libwebp-dev tcl8.5-dev tk8.5-dev python-tk -y

wget https://raw.githubusercontent.com/Nucleoos/nucleoos/master/install/ubuntu/nginx.conf
wget https://raw.githubusercontent.com/Nucleoos/nucleoos/master/install/ubuntu/upstart.conf
wget https://raw.githubusercontent.com/Nucleoos/nucleoos/master/install/ubuntu/uwsgi.ini

virtualenv env
source env/bin/activate
curl https://bootstrap.pypa.io/ez_setup.py | python
pip install -U setuptools pip
pip install uwsgi pylibmc

wget https://github.com/treeio/treeio/archive/2.0.zip
unzip 2.0.zip
rsync -a treeio-2.0/ treeio
rm -rf treeio-2.0
rm 2.0.zip

pip install -r treeio/requirements.txt

# see http://www.postgresql.org/download/linux/ubuntu/
# this should work for lucid (10.04), precise (12.04), trusty (14.04) and utopic (14.10)
echo "deb http://apt.postgresql.org/pub/repos/apt/ "$(lsb_release -a | grep Codename | awk -F' ' '{print $2}')"-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install postgresql-9.4 libpq-dev -y
sudo -u postgres createuser --pwprompt nucleoos
sudo -u postgres createdb nucleoos --owner=nucleoos
pip install psycopg2
cd treeio
python manage.py collectstatic --noinput
python manage.py installdb

#add uwsgi to upstart
sudo ln -s /opt/nucleoos/upstart.conf  /etc/init/nucleoos.conf
sudo initctl reload-configuration
sudo start nucleoos
sudo ln -s /opt/nucleoos/nginx.conf  /etc/nginx/sites-enabled/nucleoos
sudo rm  /etc/nginx/sites-enabled/default
sudo nginx -s reload
