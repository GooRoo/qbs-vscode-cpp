This module provides a handy way to use [Qbs](http://doc.qt.io/qbs/) with the [C/C++ extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools) for Visual Studio Code. It is able to pass such an information like defines, list of include paths, etc. from the build system to the extension.

## Installation and usage

### Get the module

```sh
$ mkdir 3rdParty
$ cd 3rdParty
$ git clone https://bitbucket.org/gooroo/qbs-vscode-cpp.git
```

### Add path to your root project

```qml
Project {
    qbsSearchPaths: '3rdParty/qbs-vscode-cpp'
}
```

### Use it in your sub-project

Just add a dependency:
```qml
Project {
    CppApplication {
        Depends { name: 'vscode' }
    }
}
```

Unfortunately, due to a [dumb restriction](http://doc.qt.io/qbs/custom-modules.html#project-specific-modules-and-items), it is not possible to use custom modules in the root `Project` itself.

### Pre-requisites

The module relies on the presence of `.vscode/c_cpp_properties.json` file in your root folder. If you don't have one, generate it with a **C/Cpp: Edit Configurations...** command in your Visual Studio Code.

## License

The module is distributed under the terms of [MIT license](LICENSE).
