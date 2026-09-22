create database mydatabase; --Se debe personalizar el nombre de la base de datos segun proyecto
create user 'myuser'@'%' identified by 'password'; --Se debe personalizar el nombre de usuario y la contraseña
grant all on mydatabase.* to 'myuser'@'%';