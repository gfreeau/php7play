Setup Instructions
==================

1. Create Vagrantfile
---------------------

```
$ cp Vagrantfile.dist Vagrantfile
```

2. Set VM configuration
-----------------------

```
$ vim Vagrantfile
```

```ruby
ip = "192.168.5.5"
memory = 1024
cpus = 2
folders = [
    # { "map" => "/path/to/mycode", 'to' => "/path/in/vagrant/mycode"},
]
```

3. Add hosts entry
------------------

```
$ sudo vim /etc/hosts
```

```
192.168.5.5 php7play
```

4. Vagrant up
-------------

```
$ vagrant up
```

5. Test
-------------

Open `http://php7play/` in your browser
