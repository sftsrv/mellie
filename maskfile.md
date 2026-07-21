# Tasks

Tasks are runnable using [Mask](https://github.com/jacobdeichert/mask) or by copying and running them in your terminal

## deps

```sh
gleam deps download

cd codegen
gleam deps download
```

## test

```sh
gleam test --target javascript
gleam test --target erlang
```


## snap

> Review latest snapshots

```sh
gleam run -m birdie
```

## build

```sh
gleam build

cd codegen
gleam build
```

## codegen

```sh
cd codegen
gleam run

cd ..
gleam format
gleam build
```

