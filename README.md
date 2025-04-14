## Image Content

This is a Docker image for exercises in a Wasm workshop. It puts together the following tools:

| Tool                                                                     | Notes                                                             |
| ------------------------------------------------------------------------ | ----------------------------------------------------------------- |
| [Build Essentials](https://packages.ubuntu.com/focal/build-essential)    | C Compiler, C Library, etc.                                       |
| _wget_, _curl_, _vim_                                                    | Just some useful tools                                            |
| [WebAssembly Binary Toolkit (WABT)](https://github.com/WebAssembly/wabt) | Contains useful tools like wat2wasm                               |
| [Wasmtime](https://wasmtime.dev/)                                        | A runtime for WebAssembly & WASI                                  |
| [Wasmer](https://wasmer.io/)                                             | A runtime for WebAssembly & WASIX                                 |
| [emscripten](https://emscripten.org/index.html)                          | Compiler toolchain to Wasm                                        |
| [Rust](https://www.rust-lang.org/)                                       | Rust tools for Rust-related Wasm examples                         |
| [Fermyon Spin](https://www.fermyon.com/spin)*                            | Platform for serverless Wasm apps                                 |
| [WASI SDK](https://github.com/WebAssembly/wasi-sdk)                      | WASI-enabled WebAssembly C/C++ toolchain                          |
| [Wasm Tools](https://github.com/bytecodealliance/wasm-tools)             | Rust tooling for low-level manipulation of WebAssembly modules    |
| [WIT Bindgen](https://github.com/bytecodealliance/wit-bindgen)           | Guest language bindings generator for WIT and the Component Model |
| [.NET](https://dot.net)                                                  | .NET SDK for building _Blazor_ apps                               |
| [Just](https://github.com/casey/just)                                    | Useful command runner                                             |
| [http-server](https://www.npmjs.com/package/http-server)                 | Simple static HTTP server                                         |

Note that for Rust, the _wasm32-wasip1_ target, the _wasm32-unknown-unknown_ target, [_wasm-pack_](https://rustwasm.github.io/wasm-pack/), [`cargo-wasix`](https://wasix.org/docs/language-guide/rust/installation), [WASM Composition Tooling (WAC)](https://github.com/bytecodealliance/wac), and [`cargo component`](https://github.com/bytecodealliance/cargo-component) are also installed.

Note that for .NET, the [_wasm-tools_](https://learn.microsoft.com/en-us/aspnet/core/blazor/tooling?view=aspnetcore-8.0&pivots=linux-macos#net-webassembly-build-tools) and the [_wasm-experimental_ workload](https://learn.microsoft.com/en-us/aspnet/core/client-side/dotnet-interop?view=aspnetcore-8.0#prerequisites) are also installed.

Note that for Wasm Tools, the languge toolings for [Rust](https://component-model.bytecodealliance.org/language-support/rust.html) and [JavaScript](https://component-model.bytecodealliance.org/language-support/javascript.html) are installed.

Don't forget that there are [online alternatives to running WABT locally](https://webassembly.github.io/wabt/demo/)!

*) Spin is currently disabled because of problems with running the installier in GitHub Actions.

## How to Use

- If you don't have it, install [Visual Studio Code](https://code.visualstudio.com) with the following extensions:
  - [Docker](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker)
  - [Remote Development](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack)
  - [C/C++ Extension Pack](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools-extension-pack)
  - [C#](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.csharp)
  - [Rust Analyzer](https://marketplace.visualstudio.com/items?itemName=rust-lang.rust-analyzer)
  - [crates](https://marketplace.visualstudio.com/items?itemName=serayuzgur.crates)
  - [Error Lens](https://marketplace.visualstudio.com/items?itemName=usernamehw.errorlens)
- Attach VSCode to the running container using the _Docker_ extension.

  ![Attach VSCode to container](https://github.com/rstropek/wasm-workshop/blob/main/attach.png?raw=true)

## Arguments

The Docker image accepts the following [arguments](https://docs.docker.com/engine/reference/builder/#arg):

| Argument         | Default Value  |                              |
| ---------------- | -------------- | ---------------------------- |
| `base_image`     | `ubuntu:noble` | The base image               |
| `wasi_sdk`       | `24`           | WASI SDK version             |
| `dotnet_repo`    | `24.04`        | Used .NET repository         |
| `dotnet_version` | `8.0`          | Installed .NET version       |
| `node_major`     | `20`           | Installed Node version       |
| `wasm_tools`     | `1.216.0`      | Installed Wasm Tools version |

Read more about .NET repository version [here](https://learn.microsoft.com/en-us/dotnet/core/install/linux-ubuntu#register-the-microsoft-package-repository).

## Exercises

**Note:** Not all of these exercises have been checked for the newest versions of the tools. Please let me know if you find any issues.

### Hello World Wasm

#### With C

```c
#include <stdio.h>

int main() {
    printf("Hello World\n");
    return 0;
}
```

Compile and run:

```bash
$CCWASM hello.c -o hello.wasm
wasmtime hello.wasm
```

#### With Rust

- `cargo new hello-wasm`
- Look at _src/main.rs_
- Compile and run:

  ```bash
  cargo build --target wasm32-wasi
  wasmtime target/wasm32-wasi/debug/hello-wasm.wasm
  ```

#### Exercise

Goals: Make sure that you have the necessary tools (given if you use the Docker image), get familiar with compiling code to Wasm and running it outside of the browser with Wasmtime.

- Choose C or Rust
- Implement a program that prints all Fibonacci numbers up to 1000
- Compile it to Wasm
- Run it with Wasmtime

### Introduction to Wasm with WAT

#### Hello World (Online)

![wat2wasm online](https://github.com/rstropek/wasm-workshop/blob/main/wat2wasm-online.png?raw=true)

#### Fibonacci

Try this code in the [online WAT editor](https://webassembly.github.io/wabt/demo/wat2wasm/index.html).

```wasm
(module
  ;; The memory section declares a linear memory instance and initializes it with a given contents.
  ;; Memory is array-like and can be accessed with loads and stores.
  ;; Here, we allocate 1 page of memory, which is 64KiB.
  (memory 1)

  ;; The export section makes WebAssembly functions and memory available for calling from JavaScript.
  ;; We're exporting the memory we defined above so we can manipulate it or read from it in JS.
  (export "memory" (memory 0))

  ;; The func section declares a list of functions in the module.
  (func $fibonacci
    ;; Declaring the result type of the function.
    ;; Our fibonacci function returns an i32 (32-bit integer) with the number
    ;; of elements written to memory (address 0).
    (result i32)

    ;; Defining local variables which will be used in the function.
    ;; The local.get and local.set instructions allow for manipulating them.
    (local $current i32) ;; will hold a fibonacci number
    (local $next i32) ;; will hold the subsequent fibonacci number
    (local $ptr i32) ;; will be used as a pointer to memory where to store the numbers
    (local $limit i32) ;; will define our upper bound for fibonacci calculation
    (local $temp i32) ;; temporary variable

    ;; Initializing our local variables.
    (local.set $current (i32.const 0))
    (local.set $next (i32.const 1))
    (local.set $ptr (i32.const 0))
    (local.set $limit (i32.const 100))

    ;; Storing the first two Fibonacci numbers (0 and 1) in memory.
    (i32.store (local.get $ptr) (local.get $current))
    ;; Update $ptr to point to the next memory cell.
    (local.set $ptr (i32.add (local.get $ptr) (i32.const 4)))
    (i32.store (local.get $ptr) (local.get $next))
    (local.set $ptr (i32.add (local.get $ptr) (i32.const 4)))

    ;; Loop that calculates Fibonacci numbers and stores them in memory.
    (loop $loop1
      ;; Store the sum of $current and $next in a temporary variable.
      (local.set $temp (i32.add (local.get $current) (local.get $next)))

      ;; Check if the new Fibonacci number is less than or equal to our limit.
      (if (i32.le_s (local.get $temp) (local.get $limit))
        (then
          ;; If yes, update $current to the value of $next.
          (local.set $current (local.get $next))
          ;; Update $next to the new Fibonacci number.
          (local.set $next (local.get $temp))
          ;; Store the new Fibonacci number in memory.
          (i32.store (local.get $ptr) (local.get $temp))
          ;; Update $ptr to point to the next memory cell.
          (local.set $ptr (i32.add (local.get $ptr) (i32.const 4)))
          ;; Continue loop from its beginning.
          (br $loop1)
        )
      )
    )

    ;; At the end, we return how many Fibonacci numbers have been calculated
    ;; and stored in memory by dividing the memory pointer by 4
    ;; (since WebAssembly's i32 takes up 4 bytes of memory).
    (i32.div_u (local.get $ptr) (i32.const 4))
  )

  ;; Exporting the fibonacci function so it can be called from JavaScript.
  (export "fibonacci" (func $fibonacci))
)
```

```js
const wasmInstance = new WebAssembly.Instance(wasmModule, {});
const { fibonacci } = wasmInstance.exports;
let len = fibonacci();
console.log(`We got ${len} numbers and here they are:`);
const fibonacciNumbers = new Uint32Array(wasmInstance.exports.memory.buffer);

// Extract Fibonacci numbers from memory and print them
for (let i = 0; i < len; i++) {
  console.log(fibonacciNumbers[i]);
}
```
