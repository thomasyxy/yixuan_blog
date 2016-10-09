
export PATH=$PATH:/usr/local


pwd
# npm install --production
pm2 startOrRestart ecosystem.json --env production
