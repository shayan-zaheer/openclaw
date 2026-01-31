import http from 'http'
const port = process.env.PORT || 8080
http.createServer((req, res) => {
  res.writeHead(200)
  res.end('OK')
}).listen(port)
console.log(`Health server listening on ${port}`)
