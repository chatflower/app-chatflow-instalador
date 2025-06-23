#!/bin/bash
# 
# funciones para configurar el backend de la aplicación

#######################################
# crea db docker
# Arguments:
#   None
#######################################
backend_db_create() {
  print_banner
  printf "${WHITE} 💻 Creando base de datos...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  usermod -aG docker deploy
  mkdir -p /data
  chown -R 999:999 /data
  docker run --name postgresql \
                -e POSTGRES_USER=flow \
                -e POSTGRES_PASSWORD=${pg_pass} \
				-e TZ="America/Santo_Domingo" \
                -p 5432:5432 \
                --restart=always \
                -v /data:/var/lib/postgresql/data \
                -d postgres

  docker run --name redis-izing \
                -e TZ="America/Santo_Domingo" \
                -p 6379:6379 \
                --restart=always \
                -d redis:latest redis-server \
                --appendonly yes \
                --requirepass "${redis_pass}"

  docker run -d --name portainer \
                -p 9000:9000 -p 9443:9443 \
                --restart=always \
                -v /var/run/docker.sock:/var/run/docker.sock \
                -v portainer_data:/data portainer/portainer-ce
EOF

  sleep 2
}

#######################################
# install_chrome
# Arguments:
#   None
#######################################
backend_chrome_install() {
  print_banner
  printf "${WHITE} 💻 Instalar Google Chrome...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
wget --inet4-only -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmour -o /usr/share/keyrings/chrome-keyring.gpg 
sudo sh -c 'echo "deb [arch=amd64,arm64,ppc64el signed-by=/usr/share/keyrings/chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list'
sudo apt update 
sudo apt install -y google-chrome-stable 
EOF

  sleep 2
}

#######################################
# establece variable de entorno para backend.
# Arguments:
#   None
#######################################
backend_set_env() {
  print_banner
  printf "${WHITE} 💻 Configurando variables de entorno (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # ensure idempotency
  backend_url=$(echo "${backend_url/https:\/\/}")
  backend_url=${backend_url%%/*}
  backend_url=https://$backend_url

  # ensure idempotency
  frontend_url=$(echo "${frontend_url/https:\/\/}")
  frontend_url=${frontend_url%%/*}
  frontend_url=https://$frontend_url
  
  jwt_secret=$(openssl rand -base64 32)
  jwt_refresh_secret=$(openssl rand -base64 32)

sudo su - deploy << EOF
  cat <<[-]EOF > /home/deploy/${nome_instancia}/backend/.env
NODE_ENV=dev
BACKEND_URL=${backend_url}
FRONTEND_URL=${frontend_url}

PROXY_PORT=443
PORT=${backend_porta}

# conexión con la base de datos
DB_DIALECT=postgres
DB_PORT=${porta_postgre_intancia}
DB_TIMEZONE=-04:00
POSTGRES_HOST=localhost
POSTGRES_USER=flow
POSTGRES_PASSWORD=${pg_pass}
POSTGRES_DB=postgres

# Claves para cifrado del token jwt
JWT_SECRET=${jwt_secret}
JWT_REFRESH_SECRET=${jwt_refresh_secret}

# Datos de conexión con REDIS
IO_REDIS_SERVER=localhost
IO_REDIS_PASSWORD=${redis_pass}
IO_REDIS_PORT=6379
IO_REDIS_DB_SESSION=2

#CHROME_BIN=/usr/bin/google-chrome
CHROME_BIN=/usr/bin/google-chrome-stable

# tiempo para randomización del mensaje de horario de funcionamiento
MIN_SLEEP_BUSINESS_HOURS=10000
MAX_SLEEP_BUSINESS_HOURS=20000

# tiempo para randomización de mensajes del bot
MIN_SLEEP_AUTO_REPLY=4000
MAX_SLEEP_AUTO_REPLY=6000

# tiempo para randomización de mensajes generales
MIN_SLEEP_INTERVAL=2000
MAX_SLEEP_INTERVAL=5000

# datos de RabbitMQ / Para no utilizar, simplemente comentar la var AMQP_URL
RABBITMQ_DEFAULT_USER=admin
RABBITMQ_DEFAULT_PASS=123456
# AMQP_URL='amqp://admin:123456@host.docker.internal:5672?connection_attempts=5&retry_delay=5'

# api oficial (integración en desarrollo)
API_URL_360=https://waba-sandbox.360dialog.io

# usado para mostrar opciones no disponibles normalmente.
ADMIN_DOMAIN=flowdeskpro.io

# Datos para utilización del canal de facebook
FACEBOOK_APP_ID=3237415623048660
FACEBOOK_APP_SECRET_KEY=3266214132b8c98ac59f3e957a5efeaaa13500

# Forzar utilizar versión definida vía cache (https://wppconnect.io/es/whatsapp-versions/)
#WEB_VERSION=2.2409.2

# Personalizar opciones del pool de conexiones DB
#POSTGRES_POOL_MAX=100
#POSTGRES_POOL_MIN=10
#POSTGRES_POOL_ACQUIRE=30000
#POSTGRES_POOL_IDLE=10000

# Limitar Uso del Usuario Izing y Conexiones
USER_LIMIT=99
CONNECTIONS_LIMIT=99
[-]EOF
EOF

  sleep 2
}


#######################################
# instala dependencias de node.js
# Arguments:
#   None
#######################################
backend_node_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando dependencias del backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${nome_instancia}/backend
  npm install --force --silent
EOF

  sleep 2
}

#######################################
# compila código del backend
# Arguments:
#   None
#######################################
backend_node_build() {
  print_banner
  printf "${WHITE} 💻 Compilando el código del backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${nome_instancia}/backend
  npm run build
EOF

  sleep 2
}

#######################################
# actualiza whatsapp.js
# Arguments:
#   None
#######################################
whatsappweb_update() {
  print_banner
  printf "${WHITE} 💻 Actualizando el whatsapp.js...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${nome_instancia}/backend
  pm2 stop all
  rm .wwebjs_auth -Rf
  rm .wwebjs_cache -Rf
  npm r whatsapp-web.js
  npm install github:pedroslopez/whatsapp-web.js#webpack-exodus
  pm2 restart all
EOF

  sleep 2
}

restart_pm2() {
  print_banner
  printf "${WHITE} 💻 Reiniciando PM2...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  pm2 restart all
EOF

  sleep 2
}

#######################################
# actualiza izing
# Arguments:
#   None
#######################################
git_update() {
  print_banner
  printf "${WHITE} 💻 Actualizando el flowdeskpro del git...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${nome_instancia}
  pm2 stop all
  git checkout master
  git pull
EOF

  sleep 2
}

#######################################
# ejecuta db migrate
# Arguments:
#   None
#######################################
backend_db_migrate() {
  print_banner
  printf "${WHITE} 💻 Ejecutando db:migrate...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${nome_instancia}/backend
  npx sequelize db:migrate
EOF

  sleep 2
}

#######################################
# ejecuta db seed
# Arguments:
#   None
#######################################
backend_db_seed() {
  print_banner
  printf "${WHITE} 💻 Ejecutando db:seed...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${nome_instancia}/backend
  npx sequelize db:seed:all
EOF

  sleep 2
}

#######################################
# inicia backend usando pm2 en 
# modo producción.
# Arguments:
#   None
#######################################
backend_start_pm2() {
  print_banner
  printf "${WHITE} 💻 Iniciando pm2 (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${nome_instancia}/backend
  pm2 start dist/server.js --name ${nome_instancia}-backend
  pm2 save
EOF

  sleep 2
}

#######################################
# actualiza código del frontend
# Arguments:
#   None
#######################################
backend_nginx_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando nginx (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  backend_hostname=$(echo "${backend_url/https:\/\/}")

sudo su - root << EOF

cat > /etc/nginx/sites-available/${nome_instancia}-backend << 'END'
server {
  server_name $backend_hostname;

  location / {
    proxy_pass http://127.0.0.1:${backend_porta};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
END

ln -s /etc/nginx/sites-available/${nome_instancia}-backend /etc/nginx/sites-enabled
EOF

  sleep 2
}
