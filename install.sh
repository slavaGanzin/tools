for file in `ls | grep .coffee`; do
  bin=/usr/bin/`echo $file | sed -e 's/.coffee//'`
  sudo ln -s `pwd`/$file $bin
  sudo chmod +x $bin
done
