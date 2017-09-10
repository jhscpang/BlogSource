hexo generate
cp -R public/* ../deploy/jhscpang.github.io
cd ../deploy/jhscpang.github.io
git pull origin master
git add .
git commit -m “update”
git push origin master
