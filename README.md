# music-catalog

Pre-requirements:

1. Install Ruby and Clementine
2. Run command: `sudo apt install bpm-tools sqlite3 libsqlite3-dev`
3. Run command: `bundle install`
4. Create file `config.json` with this template:

```
{
  "dir":"/path/to/music",
  "genres":{
    "z":"pé de serra",
    "x":"arrasta-pé"
  }
}
```

For `genres` you may use one letter as a key and any string as value (for title).
