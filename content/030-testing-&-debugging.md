+++
date = '2025-02-28T15:49:40+02:00'
draft = true
title = 'Testing & Debugging'
weight = 30
+++

## Questions?
1. What are some best practices for writing unit tests in Go? 
1. Explain how to use table-driven tests in Go with an example.
1. How do you handle mocking dependencies?
1. How do you debug concurrent code in Go? 
1. What is pprof and how do you use it to analyze goroutine stacks?

## Answers:

### 1. What are some best practices for writing unit tests in Go?
By following these practices, you can create more effective, maintainable, and comprehensive unit tests in Go:
- ***Use table-driven tests:*** This approach allows you to run the same test logic with different inputs and expected outputs, making tests more thorough and organized
- ***Write clear and concise test cases:*** Ensure your tests have straightforward steps and expected results
- ***Structure your tests properly:*** Include a clear title, preconditions, steps, and expected results for each test case
- ***Group tests by functionality:*** Organize test cases based on features or modules
- ***Use interfaces and mock external dependencies:*** This helps in isolating the unit being tested and avoiding external API calls or file I/O
- ***Cover edge cases and boundary conditions:*** Ensure your tests include various scenarios, including potential edge cases
- ***Use the -v flag with go test for increased verbosity:*** This provides more detailed output about test execution
- ***Parallelize tests when possible:*** This can improve test execution speed
- ***Avoid asserting error messages directly:*** Focus on testing observable behavior rather than implementation details
- ***Use subtests with t.Run():*** This allows for verifying results with various inputs in one function
- Utilize Go's built-in testing package and tools like go test -cover for coverage analysis
- Write tests that are not too closely tied to the production code to avoid frequent test breakage during refactoring

---

### 2. Explain how to use table-driven tests in Go with an example.
Table-driven tests in Go are a popular and efficient way to write unit tests for functions with multiple input scenarios. Here's how to use them:

1. Define a slice or map of test cases, each containing input parameters and expected outputs.
2. Iterate over the test cases, running the function being tested with each set of inputs.
3. Compare the actual output with the expected output for each case.

Here's an example of a table-driven test for a simple `sum` function:

```go
func TestSum(t *testing.T) {
    tests := []struct {
        name     string
        a        int
        b        int
        expected int
    }{
        {"positive numbers", 10, 5, 15},
        {"zero and positive", 0, 5, 5},
        {"negative numbers", -3, -2, -5},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := sum(tt.a, tt.b)
            if result != tt.expected {
                t.Errorf("sum(%d, %d) = %d; want %d", tt.a, tt.b, result, tt.expected)
            }
        })
    }
}
```

This approach offers several benefits:

1. Improved readability and maintainability
2. Easy addition of new test cases
3. Reduced code duplication
4. Better test coverage with multiple scenarios

Table-driven tests are particularly useful for functions with multiple input parameters or complex logic requiring various test scenarios.

---

### 3. How do you handle mocking dependencies?

---

### 4. How do you debug concurrent code in Go?
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

### 5. What is pprof and how do you use it to analyze goroutine stacks?
`pprof` is a powerful profiling tool for Go programs that allows developers to analyze CPU usage, memory allocations, and goroutine behavior. It's part of the Go standard library and can generate detailed profiles of Go programs. To use pprof for analyzing goroutine stacks:
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

By using pprof to analyze goroutine stacks, developers can identify issues such as goroutine leaks, deadlocks, and performance bottlenecks in their Go programs.

---
