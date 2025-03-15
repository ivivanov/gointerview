+++
date = '2025-03-01T10:56:24+02:00'
draft = false
title = 'Debugging'
slug = 'debugging'
weight = 31
+++

## Questions?
1. How do you debug concurrent code in Go? 
1. What is `pprof`? Name few key features.
1. How do you use `pprof` to analyze goroutine stacks?
1. What are the usual challenges debugging production-grade applications?
1. How do you debug and resolve production issues?

## Answers:

### 1. How do you debug concurrent code in Go?
Here are some examples of how to debug concurrent code in Go:

- Using Delve debugger:

	```bash
	dlv debug
	(dlv) break main.go:line
	(dlv) continue
	(dlv) goroutines
	(dlv) goroutine 1 next
	(dlv) print var_name
	(dlv) locals
	```

- Race detector:
A race condition occurs when two or more concurrent operations access shared data and at least one of them modifies it, potentially leading to unpredictable behavior due to the timing and sequence of the operations.

	Example:
	```go
	var counter int
	var wg sync.WaitGroup
	wg.Add(2)

	go func(wg *sync.WaitGroup) {
		counter++
		wg.Done()
	}(&wg)

	go func(wg *sync.WaitGroup) {
		counter++
		wg.Done()
	}(&wg)

	wg.Wait()
	```

	```bash
	go run -race .
	```

- Logging with goroutine IDs:

	```go
	func goID() int {
		var buf [64]byte
		n := runtime.Stack(buf[:], false)
		idField := strings.Fields(strings.TrimPrefix(string(buf[:n]), "goroutine "))[0]
		id, err := strconv.Atoi(idField)
		if err != nil {
			panic(err)
		}
		return id
	}

	func main() {
		ch := make(chan int) // Unbuffered channel

		go func() {
			log.Printf("Goroutine %d:*** Starting work", goID())

			ch <- 42 // Blocks until receiver is ready
		}()

		value := <-ch // Blocks until sender sends data
		fmt.Println(value)
	}
	```

- Visualizing goroutines with execution trace:

	```bash
	go test -trace trace.out
	go tool trace trace.out
	```

- Naming goroutines for easier identification:

	```go
	runtime.SetFinalizer(go func() {
		debug.SetGoroutineLabels(context.TODO(), "worker")
		// ... worker logic
	}(), nil)
	```

These examples demonstrate various techniques for debugging concurrent Go code, from using specialized debuggers to leveraging built-in Go tools for analysis and visualization.

---

### 2. What is `pprof`? Name few key features.
`pprof` is a powerful profiling tool for Go programs that allows developers to analyze CPU usage, memory allocations, and goroutine behavior. It's part of the Go standard library and can generate detailed profiles of Go programs.  Key features of pprof include:
- ***CPU profiling:*** Collects CPU usage data to identify time spent in different parts of the application
- ***Memory profiling:*** Records heap allocations to monitor memory usage and detect potential leaks
- ***Block profiling:*** Identifies locations where goroutines block or wait for synchronization
- ***Mutex profiling:*** Reports on mutex contention in the application
- ***Visualization capabilities:*** Generates both text and graphical reports for analysis
- ***HTTP server integration:*** Can serve profiling data via HTTP for easy access
- ***Symbolization:*** Can translate machine addresses to human-readable function names and line numbers
- ***Comparison and aggregation:*** Allows comparing or combining multiple profiles for analysis
- ***Customizable reporting:*** Offers options to adjust granularity (e.g., functions, files, lines) and sorting of results

---

### 3. How do you use `pprof` to analyze goroutine stacks?
To use pprof for analyzing goroutine stacks:

#### Enable profiling in your Go program:
- Import the pprof package:*** `import _ "net/http/pprof"`
- Start an HTTP server:*** 
	```go
	go func() {
		log.Println(http.ListenAndServe("localhost:1414", nil))
	}()
	```

#### Generate a goroutine profile:
- Access the pprof endpoint:*** `http://localhost:1414/debug/pprof/goroutine?debug=2`
- This provides a full goroutine stack dump

#### Analyze the profile:
- Use the `go tool pprof` command to examine the generated profile
- For example:*** `go tool pprof http://localhost:1414/debug/pprof/goroutine`

#### Interpret the results:
- pprof groups goroutines by stack trace signature
- It provides information on goroutine states, function calls, and parameter signatures

#### Visualize the data:
- pprof can generate various reports, including CPU usage summaries, memory allocation details, and flame graphs

---

### 4. What are the usual challenges debugging production-grade applications?
Debugging production-grade applications presents several challenges:

- ***Infrastructures:*** Distributed systems, serverless architectures, and microservices make it difficult to trace issues to their source
- ***Limited visibility:*** Modern infrastructures often reduce visibility into software behavior, making it harder to understand and debug production environments
- ***Remote debugging:*** When issues occur in production, developers may not have direct access to the local environment. Debugging in production can potentially disrupt current users, slow down application performance, or even crash the app
- ***Data differences:*** Production environments often use different datasets than development or QA, leading to unforeseen issues
- ***Reproducing issues:*** It can be challenging to replicate production problems in local or staging environments
- ***Log analysis:*** Sifting through numerous log files to find relevant data is time-consuming and may require writing additional logs and redeploying the application
- ***Unpredictable bugs:*** Some bugs may manifest in unexpected ways, making them difficult to pinpoint and resolve
- ***Balancing speed and quality:*** Developers must maintain equilibrium between quick fixes and thorough, high-quality solutions

---

### 5. How do you debug and resolve production issues?
To debug and resolve production issues effectively, follow these key steps:

1. Steps to reproduce
	- Gather context from user reports, error descriptions, and logs
	- Define conditions under which the issue occurs
	- Set up a test environment to recreate production-like conditions

2. Logs and metrics
	- Examine application, server, and infrastructure logs
	- Use monitoring tools to identify anomalies in system health parameters
	- Compare data before, during, and after the issue

3. Root cause analysis
	- Generate hypotheses based on collected data
	- Test hypotheses through controlled experiments
	- Trace code paths and analyze dependencies

4. Collaborate
	- Involve relevant stakeholders - Devs, QAs, DevOps
	- Assign clear roles and responsibilities

5. Implement fix
	- Develop a solution addressing the root cause
	- Conduct thorough peer reviews and testing
	- Deploy gradually using techniques like canary releases
	- Monitor closely post-deployment for regressions

6. Document
	- Record findings and decisions made during the process
	- Conduct post-mortem discussions to identify process improvements
	- Update documentation and implement preventive measures

7. Follow good practices 
	- Use logging frameworks for detailed insights
	- Implement proper error handling and logging in the codebase
	- Utilize production debugging tools for real-time monitoring and analysis
	- Have a well-versed production debugging team ready to respond quickly

---
