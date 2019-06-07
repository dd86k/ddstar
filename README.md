# ddstar: Asterisk Dashboard

```
+----------+       +--------+       +-------------+
| Asterisk | <=+=> | ddstar | <=+=> | Web Page    |
+----------+   |   +--------+   |   | Application |
AMI -----------+                |   +-------------+
HTTP/Websocket+JSON ------------+
```

_They told me to be a star, so I made one._

ddstar aims to be a modern and simple dashboard and operator panel solution for
the Asterisk Project that can even act as a Web proxy on Linux and Windows
platforms.

**NOTE:** This project is currently NOT production-ready.

# Compiler Support

| Compiler | Description |
|---|---|
| DMD | Lowest optimizations. Most compatible, recommended. |
| LDC | Highest optimizations. May be a little buggy. |
| GDC | Medium optimizations. Untested, may buggy. |