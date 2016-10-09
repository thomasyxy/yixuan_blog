
export PATH=$PATH:/usr/local/bin


node -v
pwd
# npm install --production
pm2 startOrRestart ecosystem.json --env production
