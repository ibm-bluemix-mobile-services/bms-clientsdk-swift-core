
use_frameworks!



# Methods

def pod_BMSAnalyticsSpec
	pod 'BMSAnalyticsSpec', '~> 0.0.14'
end

def import_pods_iOS
	platform :ios, '8.0'
    pod_BMSAnalyticsSpec
end

def import_pods_watchOS
	platform :watchos, '2.0'
    pod_BMSAnalyticsSpec
end



# Targets

target 'BMSCore' do
	import_pods_iOS
end

target 'BMSCoreTests' do
    import_pods_iOS
end

target 'BMSCoreWatchOS' do
	import_pods_watchOS
end

target 'TestAppiOS' do
	import_pods_iOS
end

target 'TestAppWatchOS' do

end

target 'TestAppWatchOS Extension' do
	import_pods_watchOS
end

