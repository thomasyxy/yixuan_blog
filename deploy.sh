
export PATH=$PATH:/usr/local


pwd
# npm install --production
npm install && pm2 startOrRestart ecosystem.json --env production
