# Create admin
cd /opt/webwork/courses
/opt/webwork/webwork2/bin/addcourse admin --users=adminCourselist.lst
chown -R www-data:www-data admin
SKIP_UPLOAD_OPL_STATISTICS=1 /opt/webwork/webwork2/bin/OPL-update 
