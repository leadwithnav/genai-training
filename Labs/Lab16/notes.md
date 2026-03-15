Act as a Senior Performance Test Engineer responsible for planning load testing of an eCommerce platform.

Based on the information provided, analyze the requirements and determine what critical performance testing inputs are missing before designing load tests.

Consider the following areas:

expected user traffic and concurrency levels

workload model and transaction distribution

service-level objectives (SLA/SLO) such as response time and error thresholds

throughput targets (TPS/RPS)

ramp-up strategy and test duration

production vs test environment capacity differences

data volume and test data availability

caching/CDN behavior

autoscaling policies

monitoring metrics required during test execution

third-party dependencies (payment gateways, APIs, etc.)

Provide the output in four sections:

1. Requirements Already Provided
2. Critical Missing Requirements
3. Questions the Performance Testing Team Should Ask Stakeholders
4. Assumptions That May Need to Be Derived if Data Is Not Availabl


pip install numpy matplotlib uv

git clone https://github.com/QAInsights/jmeter-mcp-server.git
cd jmeter-mcp-server

JMETER_HOME=C:\Tools\apache-jmeter-5.6.3
JMETER_BIN=C:\Tools\apache-jmeter-5.6.3\bin\jmeter.bat
JMETER_JAVA_OPTS=-Xms1g -Xmx2g

uv sync
uv pip install python-dotenv numpy matplotlib
uv run jmeter_server.py


"jmeter": {
			"command": "C:\\Users\\Lenovo\\AppData\\Local\\Programs\\Python\\Python313\\Scripts\\uv.exe",
			"args": [
				"--directory",
				"D:\\jmeter-mcp-server",
				"run",
				"jmeter_server.py"
			]
		},

