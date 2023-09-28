# Bootnode Url Utilility

### Build the binary
```shell
$ go build .
```

#### Creating bootnode keys

#### If you wish to generate nodeurls for a single key.
Generate the nodeurls for a given bootkey.txt

```shell
$ ./quai-bootnode-util bootnode.key > nodeurls.txt 
```
#### If you wish to gneerate nodeurls for many keys.
Create the keys.yml file that you wish to read bootnode keys off of.

```shell
$ cp keys.yml.dist keys.yml
```

Convert the keys.yml into a folder of nodekeys.
```shell
$ ./convert.sh
```

Convert the nodekeys into a folder of nodeurls.txt.
```shell
$ ./create_enodes.sh
```

Convert the nodekeys into a static-nodes.json that can be moved to ~/.quai
```shell
$ ./create_static_nodes.sh
```