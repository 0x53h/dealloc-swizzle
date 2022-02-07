class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    rootViewController = UIViewController.alloc.init
    rootViewController.title = 'DeallocSwizzle'
    rootViewController.view.backgroundColor = UIColor.whiteColor

    navigationController = UINavigationController.alloc.initWithRootViewController(rootViewController)

    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.rootViewController = navigationController
    @window.makeKeyAndVisible

    puts "Creating rules...\n"
    # Swizzler.swizzleDeallocForClass(SampleRule)
    rule1 = SampleRule.new
    rule2 = SampleRule.new
    # Swizzler.swizzleDeallocForObject(rule2)

    true
  end
end
