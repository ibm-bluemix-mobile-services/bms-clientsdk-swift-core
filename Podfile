
use_frameworks!



# Methods

def pod_BMSAnalyticsAPI
	pod 'BMSAnalyticsAPI', '~> 0'
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

target 'BMSCore iOS' do
	import_pods_iOS
end

target 'BMSCore watchOS' do
    import_pods_watchOS
end

target 'BMSCore Tests' do
    import_pods_iOS
end

target 'TestApp iOS' do
	import_pods_iOS
end

target 'TestApp watchOS' do

end

target 'TestApp watchOS Extension' do
	import_pods_watchOS
end

