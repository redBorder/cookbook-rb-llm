cookbook-rb-ai CHANGELOG
===============

## 0.1.4
  - Pablo Pérez
    - [aaa2eb7] Rubocop made me do this
    - [52310c1] deleted ExecStart in drop-in
    - [40961da] refactor to avoid warnings
    - [6571629] Using default ruby File instead Chef::File
    - [2e5c134] Fix syntax error + little refactor
    - [4caaa53] check_if_need_to_download_model now restarts the service only if is a different model

## 0.1.3

  - Pablo Pérez
    - [7f12745] ExecStart cant be overriden - clean the value before the override
    - [2c4197f] replaced double quote to single quote to pass the lint tests
    - [6a9a5be] added with variables

## 0.1.2

  - Miguel Negrón
    - [927bc0a] Add pre and postun to clean the cookbook

## 0.1.1

  - Luis Blanco
    - [4f1cd42] user settings for vscode ignore
  - Rafael Gomez
    - [54b1298] redborder-ai user can not login

## 0.1.0

  - Miguel Negrón
    - [7215ac2] Merge pull request #4 from redBorder/feature/#18290_add_option_setup_cores_on_redborder-ai_will_use
  - Miguel Negrón
    - [fe1552d] Adapt redborder-ai
    - [2c2e2e6] Rename override.conf to redborder_cpu.conf
  - Pablo Pérez
    - [22cbf06] rename variable
    - [6eeba50] setup drop-in
    - [9a7e10d] Added drop in template!

## 0.0.2

  - Pablo Pérez
    - [8c2bbf4] Check to use sync ip or management ip
    - [a982f08] Consul port fixed

## 0.0.1

  - Pablo Pérez
    - [58b1a43] First version
