# Build

## Solution 1

### Actions

- Action 1 (see [cross-compile-appflowy-cloud-buildx.yml](../.github/workflows/cross-compile-appflowy-cloud-buildx.yml)) to compile (both amd64 and aarch64) AppFlowy and other dependencies with buildx (see [Dockerfile.build](Dockerfile.build))
- Action 2 to create the add-on:
  - first stage based on the docker image crated with action 1
  - second stage based on BUILD_FROM where all the compiled executables are copied from the first stage

### Result

Action 1 is failing to compile AppFlowy for aarch64 due to following error:

``` bash
#14 730.4 error: could not compile `regex-syntax` (lib)
#14 730.4 
#14 730.4 Caused by:
#14 730.4   process didn't exit successfully: `rustc --crate-name regex_syntax --edition=2021 /root/.cargo/registry/src/index.crates.io-6f17d22bba15001f/regex-syntax-0.8.2/src/lib.rs --error-format=json --json=diagnostic-rendered-ansi,artifacts,future-incompat --crate-type lib --emit=dep-info,metadata,link -C opt-level=3 -C codegen-units=1 --cfg 'feature="default"' --cfg 'feature="std"' --cfg 'feature="unicode"' --cfg 'feature="unicode-age"' --cfg 'feature="unicode-bool"' --cfg 'feature="unicode-case"' --cfg 'feature="unicode-gencat"' --cfg 'feature="unicode-perl"' --cfg 'feature="unicode-script"' --cfg 'feature="unicode-segment"' -C metadata=a5dfb19fe88f809e -C extra-filename=-a5dfb19fe88f809e --out-dir /appflowy_cloud/AppFlowy-Cloud/target/release/deps -L dependency=/appflowy_cloud/AppFlowy-Cloud/target/release/deps --cap-lints allow` (signal: 11, SIGSEGV: invalid memory reference)
```

## Solution 2

### Actions

- Action 1 to create the add-on:
  - first stage based on BUILD_FROM to compile AppFlowy and other dependencies
  - second stage based on BUILD_FROM where all the compiled executables are copied from the first stage

### Result

Solution is working but it takes a lot of time (> 3 hours for aarch64) and home-assistant/builder@master is not handling the cache for multistage build (-cache-to type=registry,**mode=max**).

It it strange that the action is not failing since home-assistant/builder@master is using buildx under the hood.

## Solution 3

### Actions

- Action 1 (see [cross-compile-appflowy-cloud-ubuntu.yml](../.github/workflows/cross-compile-appflowy-cloud-ubuntu.yml)) to (cross)compile AppFlowy and release the executables
- Action 2 (see [build-appflowy-cloud-container.yml](../.github/workflows/build-appflowy-cloud-container.yml)) to create the add-on:
  - first stage based on BUILD_FROM to compile other dependencies
  - second stage based on BUILD_FROM where all the compiled executables are copied from the first stage and from the releases of the action 1

### Result

The solution is working but there is still room for improvement since cache is not working and we are compiling executable in both actions.
