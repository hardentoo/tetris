# project-template

![alt text](https://cloud.githubusercontent.com/assets/26207755/26288183/98267fe0-3e8c-11e7-9b46-90af8662fcd8.gif)

![alt text](https://cloud.githubusercontent.com/assets/26207755/26288184/9a75ef74-3e8c-11e7-863f-7ab9d20e0d59.gif)

[![Build Status](https://travis-ci.org/cmc-haskell-2017/project-template.svg?branch=master)](https://travis-ci.org/cmc-haskell-2017/project-template)

Шаблон проекта для выполнения практического задания.

## Сборка и запуск

Соберите проект при помощи [утилиты Stack](https://www.haskellstack.org):

```
stack setup
stack build
```

Собрать и запустить проект можно при помощи команды

```
stack build && stack exec my-project
```

Запустить тесты можно при помощи команды

```
stack test
```

Чтобы запустить интепретатор GHCi и автоматически подгрузить все модули проекта, используйте команду

```
stack ghci
```

