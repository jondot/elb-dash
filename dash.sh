browser-sync start --server --files 'index.html, dist/*.js' &
node_modules/watchify/bin/cmd.js -t coffee-reactify app.cjsx -o dist/bundle.js -v

