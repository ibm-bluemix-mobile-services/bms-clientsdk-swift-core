
use_frameworks!



# Methods

def pod_BMSAnalyticsAPI
	pod 'BMSAnalyticsAPI', '~> 0.0.20'
end

def import_pods_iOS
	platform :ios, '8.0'
    pod_BMSAnalyticsAPI
end

def import_pods_watchOS
	platform :watchos, '2.0'
    pod_BMSAnalyticsAPI
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

