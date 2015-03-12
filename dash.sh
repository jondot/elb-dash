browser-sync start --server --files 'index.html, dist/*.js' &
watchify -t coffee-reactify app.cjsx -o dist/bundle.js -v

