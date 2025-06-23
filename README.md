[![Grupo do WhatsApp](https://img.shields.io/badge/Grupo_Whatsapp-FlowDeskPro-blue)](https://chat.whatsapp.com/Ge1rB20Cp6JA5QbIX4ZulJ)

## CREAR SUBDOMINIO Y APUNTAR AL IP DE SU VPS

Probado en ubuntu 20 y 22

Editar archivo config y colocar contraseñas de su preferencia y su email, dominios.

Si quiere instalar 2 instancias cambiar nombre de la instancia, puerto backend, puerto frontend y puerto_postgre_instancia, no debe utilizar mismos puertos de otras instalaciones

La opción actualizar va a obtener la última versión del repositorio usado para instalar

Nunca usar puertos 80 y 443 para backend utilice puerto 3000 a 3100 y frontend 4000 a 4100

## VERIFICAR PROPAGACIÓN DEL DOMINIO

https://dnschecker.org/

## EJECUTAR LOS COMANDOS ABAJO ##

Antes de iniciar verifique en el sitio de arriba si propagó el dns. Para no tener error en la instalación

Para evitar errores recomendado actualizar sistema y después de actualizar reiniciar para evitar errores

```bash
apt -y update && apt -y upgrade
```
```bash
reboot
```

Después de reiniciar seguir con la instalación

```bash
cd /root
```
```bash
git clone https://github.com/basorastudio/instalador-flowdeskpro.git instaladorflowdeskpro
```
Editar datos con sus datos, con nano para guardar presiona Ctrl + x
```bash
nano ./instaladorflowdeskpro/config
```
```bash
sudo chmod +x ./instaladorflowdeskpro/flowdeskpro
```
```bash
cd ./instaladorflowdeskpro
```
```bash
sudo ./flowdeskpro
```

## ¿Problemas de conexión whatsapp? ##

Intente actualizar el Conector WWebJS whatsapp.js

## Recomendación de instalar y dejar Firewall activado

Su servidor puede sufrir ataques externos que hacen que el sistema se cuelgue y tenga caídas por favor instale y mantenga el firewall activado.
Utilizado UFW para saber más busque en google.

## Alterar Frontend

Para cambiar nombre de la aplicación:

/home/deploy/flowdeskpro/frontend/quasar.conf

/home/deploy/flowdeskpro/frontend/src/index.template.html

Para alterar logos e íconos:

carpeta /home/deploy/flowdeskpro/frontend/public

Para alterar colores:

/home/deploy/flowdeskpro/frontend/src/css/app.sass

/home/deploy/flowdeskpro/frontend/src/css/quasar.variables.sass

Siempre alterar usando usuario deploy puede conectar al servidor con aplicación Bitvise SSH Client. Después de las alteraciones compilar nuevamente el Frontend

```bash
su deploy
```
```bash
cd /home/deploy/flowdeskpro/frontend/
```
```bash
export NODE_OPTIONS=--openssl-legacy-provider
```
```bash
npx quasar build -P -m pwa
```

Probar las alteraciones en pestaña anónima

## Errores

"Internal server error: SequelizeConnectionError: could not open file \"global/pg_filenode.map\": Permission denied"

```bash
docker container restart postgresql
```
```bash
docker exec -u root postgresql bash -c "chown -R postgres:postgres /var/lib/postgresql/data"
```
```bash
docker container restart postgresql
```

## Acceso Portainer generar contraseña
"Your Portainer instance timed out for security purposes. To re-enable your Portainer instance, you will need to restart Portainer."

```bash
docker container restart portainer
```

Después acceda nuevamente a la url http://suip:9000/

