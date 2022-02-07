# RubyMotion iOS 15.2.1 arm64 Crash #

# Symptoms #

`bundle exec rake simulator device_name="iPad mini 4 (iOS 15.2)"` runs
flawlessly, but `bundle exec rake device` crashes with:

```lldb
* thread #1, queue = 'com.apple.main-thread', stop reason = EXC_BREAKPOINT (code=1, subcode=0x1998bea58)
    * frame #0: 0x00000001998bea58 libobjc.A.dylib`object_getClass + 48
      frame #1: 0x00000001044f1828 DeallocSwizzle`rb_vm_dispatch + 5476
      frame #2: 0x00000001043e27bc DeallocSwizzle`vm_dispatch + 1028
      frame #3: 0x00000001043e4340 DeallocSwizzle`rb_scope__dealloc__(self=0x000038397eb41f80) at base_rule.rb:6
```

# Build #

```shell
bundle config set --local path 'vendor/bundle'
bundle install
```


To build using the default simulator, run: `rake` (alias `rake
simulator`).

To run on a specific type of simulator:
```shell
bundle exec rake simulator device_name="iPad mini 4 (iOS 15.2)"
```

To run on device:
```shell
bundle exec rake device
```

# Configure Provisioning Profile #

In your `Rakefile`, set the following values:

```ruby
#This is only an example, the location where you store your provisioning profiles is at your discretion.
app.codesign_certificate = "iPhone Development: xxxxx" #This is only an example, you certificate name may be different.

#This is only an example, the location where you store your provisioning profiles is at your discretion.
app.provisioning_profile = './profiles/development.mobileprovision'
```
