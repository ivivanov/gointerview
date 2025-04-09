+++
date = '2025-03-07T15:41:30+02:00'
draft = false
title = 'Patterns'
slug = 'patterns'
weight = 40
+++

# Efficient Concurrent Go
*Design Pattern Questions for Tech Interviews*

## Questions?
1. What concurrency design patterns are you familiar with?
1. Worker Pool
1. Fan-Out/Fan-In
1. What are the key differences between "fan-out/fan-in" and "worker pool"  patterns?
1. Pipeline

## Answers:

### 1. What concurrency design patterns are you familiar with?
- ***Worker Pool:*** Managing task execution across multiple goroutines
- ***Fan-Out/Fan-In:*** Distributing tasks and collecting results
- ***Producer-Consumer:*** Decoupling data production from consumption via buffer
- ***Pipeline:*** Processing data in stages
- ***Generator:*** Functions that return channels
- ***Multiplexing:*** Combining multiple channels
- ***Timeout:*** Adding time limits to goroutine execution
- ***Quit Signal:*** Gracefully stopping goroutines
- ***Bounded Parallelism:*** Limiting concurrent execution
- ***Context:*** Managing cancellation and deadlines across goroutines
- ***Semaphore:*** Controlling access to shared resources

---

### 2. Worker Pool

The worker pool pattern is a concurrency design that manages a fixed number of worker goroutines to process tasks from a shared queue. It efficiently handles large numbers of independent tasks while controlling resource usage. Workers continuously pull tasks, process them concurrently, and send results to an output queue. This pattern prevents system overload, improves performance through parallel processing, and maintains predictable resource utilization, making it ideal for scenarios like batch operations or API request handling.

#### Problems Solved by Worker Pool Pattern
1. Resource Management
   - Limits concurrent operations to prevent system overload
   - Controls memory usage by capping goroutine count
   - Avoids thread/goroutine spawning overhead

1. Efficient Concurrency
   - Processes N jobs in ~(N/Workers) seconds vs N sec sequentially
   - Reuses existing workers instead of creating per-task goroutines
   - Balances workload across available CPU cores

1. Task Coordination  
   - Ensures orderly processing of tasks
   - Provides clean shutdown mechanism
   - Enables result collection/aggregation

#### Key Advantages
- Predictable resource usage
- Better error handling
- Improved performance scaling
- Easier monitoring/debugging
- Graceful shutdown capabilities

#### Example:

```go
package main

import (
    "fmt"
    "sync"
    "time"
)

func worker(id int, jobs <-chan int, results chan<- int, wg *sync.WaitGroup) {
    defer wg.Done()
    for job := range jobs { // Automatically exits when jobs channel closes
        fmt.Printf("Worker %d processing job %d\n", id, job)
        time.Sleep(time.Second) // Simulate work
        results <- job * 2      // Send result
    }
}

func main() {
    const numJobs = 5
    const numWorkers = 3

    jobs := make(chan int, numJobs)
    results := make(chan int, numJobs)
    wg := sync.WaitGroup{}

    // Start worker pool
    for w := 1; w <= numWorkers; w++ {
        wg.Add(1)
        go worker(w, jobs, results, &wg)
    }

    // Send jobs to workers
    for j := 1; j <= numJobs; j++ {
        jobs <- j
    }
    close(jobs) // Signal no more jobs will be sent

    // Wait for all workers to finish processing
    wg.Wait()
    close(results) // Safe to close results after all workers exit

    // Collect and print results
    fmt.Println("\nResults:")
    for result := range results {
        fmt.Printf("Result: %d\n", result)
    }
}
```

#### Flow
1. Workers start and block waiting for jobs.
    - 3 workers process 5 jobs concurrently
1. Each worker:
    - Receives jobs from `jobs` channel
    - Processes job (simulated with 1s sleep)
1. Workers process jobs concurrently.
    - Send results to `results` channel
    - Exit when jobs channel closes
1. After all jobs complete:
   - Workers exit via closed jobs channel
   - Results channel closes
1. Main collects and prints results.
    - `sync.WaitGroup` ensures main waits for worker completion
    - Closing channels signals completion:
        - `close(jobs)` triggers worker exit
        - `close(results)` enables safe result collection

#### Example Use Cases:
- Batch processing large datasets
- Handling API rate limits
- Image/video processing pipelines
- Database operation queues
- Concurrent network requests

---

### 3. Fan-Out/Fan-In

The fan-out/fan-in pattern is a concurrency design used to parallelize and coordinate tasks. In the fan-out stage, a single task is divided into smaller subtasks executed concurrently by multiple goroutines. The fan-in stage collects and combines results from all subtasks. This pattern improves performance by distributing workload across goroutines, enabling parallel processing. It's implemented using goroutines and channels in Go, making it efficient for handling large-scale, divisible tasks.

#### Problems Solved by the Pattern
1. High-volume processing 
    - Distributes workloads across multiple workers
    - Handle large datasets or tasks efficiently
    - Processes independent tasks concurrently to minimize total execution time

1. Resource optimization
    - Limits concurrent operations to prevent system overload 
    - Maximizing CPU utilization

1. Result aggregation 
    - Simplifies collecting outputs from parallel operations into a unified stream
    
#### Key Advantages
- ***Scalability:*** Easily adjust worker count to match workload demands
- ***Decoupled components:*** Workers operate independently, improving fault isolation
- ***Order-agnostic processing:*** Ideal for tasks where result order doesn't matter
- ***Cost efficiency:*** Reduces cloud costs via optimized resource usage (e.g., AWS Lambda parallel invocations)

#### Example:
```go
package main

import (
	"fmt"
	"sync"
	"time"
)

func worker(id int, jobs <-chan int, results chan<- int, wg *sync.WaitGroup) {
	defer wg.Done()
	for job := range jobs {
		fmt.Printf("Worker %d processing job %d\n", id, job)
		time.Sleep(500 * time.Millisecond) // Simulate work
		results <- job * 2
	}
}

func main() {
	const (
		numJobs    = 10
		numWorkers = 3
	)

	jobs := make(chan int, numJobs)
	results := make(chan int, numJobs)
	var wg sync.WaitGroup

	// Fan-Out: Start worker pool
	for w := 1; w <= numWorkers; w++ {
		wg.Add(1)
		go worker(w, jobs, results, &wg)
	}

	// Feed jobs to workers
	go func() {
		for j := 1; j <= numJobs; j++ {
			jobs <- j
		}
		close(jobs)
	}()

	// Fan-In: Collect results
	go func() {
		wg.Wait()
		close(results)
	}()

	// Process aggregated results
	for result := range results {
		fmt.Printf("Result: %d\n", result)
	}
}
```

#### Code Flow Explanation
1. Initialization
   - Create buffered channels for jobs and results
   - Initialize WaitGroup for worker synchronization

1. Fan-Out Phase
   - Launch worker goroutines that pull from `jobs` channel
   - Each worker processes jobs concurrently

1. Job Distribution
   - Feed jobs to workers via channel
   - Close channel when done to trigger worker exit

1. Fan-In Phase
   - Close results channel after all workers complete
   - Enables clean exit from results loop

1. Result Aggregation
   - Main thread processes combined outputs

#### Example Use Cases:
- Real-time data processing (IoT sensor streams)
- Bulk image/video transcoding
- Distributed web scraping
- Concurrent API request handling
- Log aggregation from multiple sources
- ETL (Extract-Transform-Load) pipelines

---

### 4. What are the key differences between "fan-out/fan-in" and "worker pool"  patterns?

The key differences between the "fan-out/fan-in" pattern and the "worker pool" pattern are:

1. Task Distribution:
   - Fan-out/fan-in: Dynamically creates goroutines for each task, potentially leading to a large number of concurrent goroutines.
   - Worker pool: Uses a fixed number of worker goroutines that process tasks from a shared queue.

1. Concurrency Control:
   - Fan-out/fan-in: Offers less control over maximum concurrency, as it can spawn many goroutines.
   - Worker pool: Provides better control over resource usage by limiting the number of concurrent workers.

1. Flexibility:
   - Fan-out/fan-in: More flexible for handling varying workloads and task types.
   - Worker pool: Better suited for consistent workloads and similar task types.

1. Resource Management:
   - Fan-out/fan-in: May require additional mechanisms like semaphores or rate limiters for resource control.
   - Worker pool: Inherently manages resources by limiting the number of concurrent workers.

1. Implementation Complexity:
   - Fan-out/fan-in: Can be simpler to implement for small-scale tasks.
   - Worker pool: May require more setup but offers better long-term scalability.

Both patterns can be used for concurrent processing, and the choice depends on specific application requirements and resource constraints.

---

### 5. Producer-Consumer

The producer-consumer pattern is a concurrency design pattern where one or more producer threads generate data or tasks, and one or more consumer threads process or execute them. This pattern uses a shared queue as an intermediary, allowing producers and consumers to work independently and at different rates. It helps decouple data production from consumption, enables efficient workload distribution, and facilitates resource management in concurrent systems.

#### Problems Solved
- ***Concurrent Access:*** Prevents race conditions when multiple producers/consumers access shared resources
- ***Rate Mismatch:*** Buffers data when production and consumption speeds differ
- ***Resource Management:*** Avoids overwhelming systems by limiting concurrent processing (backpressure)
- ***Decoupling:*** Separates data generation logic from processing logic

#### Key Advantages
- ***Modularity:*** Producers and consumers operate independently
- ***Scalability:*** Easily add more producers/consumers without redesign
- ***Efficiency:*** Enables parallel processing and load balancing
- ***Backpressure Handling:*** Prevents system overload via bounded buffers

#### Common Use Cases
- ***Real-Time Data:*** Stock tickers, sensor data processing
- ***Task Queues:*** Web servers handling HTTP requests
- ***Logging Systems:*** Aggregating logs from multiple sources
- ***Distributed Systems:*** Asynchronous communication between microservices

---

### 6. Pipeline

The pipeline pattern is a concurrency design pattern used to process data sequentially through multiple stages, where each stage performs a specific operation and passes the result to the next stage via channels. It enables efficient and modular data processing.

#### Problems Solved by the Pattern
- ***Sequential Data Processing:*** Handles multi-step workflows where data needs to be transformed or processed in stages
- ***Concurrency:*** Allows multiple stages to run concurrently, improving performance
- ***Decoupling:*** Separates logic for each stage, making the code more modular and easier to maintain
- ***Scalability:*** Efficiently processes large datasets by leveraging parallelism

#### Key Advantages
- ***Modularity:*** Each stage is independent, making it easy to add, remove, or modify stages without affecting the rest of the pipeline
- ***Concurrent Execution:*** Multiple stages can operate simultaneously, reducing overall processing time
- ***Improved Throughput:*** Enables efficient use of CPU and I/O resources by processing data in parallel
- ***Error Handling:*** Errors can be isolated and handled at specific stages without affecting others

#### Common Use Cases
- ***ETL (Extract, Transform, Load):*** Processing and transforming large datasets
- ***Image or Video Processing Pipelines:*** Sequential operations like resizing, filtering, and saving images
- ***Text Analysis:*** Tokenization, filtering, and sentiment analysis of text data
- ***Financial Data Analysis:*** Sequential calculations on large streams of financial data
- ***Log Processing:*** Filtering, transforming, and aggregating logs in real-time

#### Example:

```go
package main

import (
	"fmt"
	"math/rand"
	"time"
)

func produce(num int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for i := 0; i < num; i++ {
			out <- rand.Intn(100) // Generate random numbers
		}
	}()
	return out
}

func double(input <-chan int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for value := range input {
			out <- value * 2 // Double the value
		}
	}()
	return out
}

func filterGt10(input <-chan int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for value := range input {
			if value > 10 { // Filter values greater than 10
				out <- value
			}
		}
	}()
	return out
}

func main() {
	rand.Seed(time.Now().UnixNano())    // Seed random number generator
	numbersCh := produce(10)            // Stage 1: Generate random numbers
	doubledCh := double(numbersCh)      // Stage 2: Double the numbers
	filteredCh := filterGt10(doubledCh) // Stage 3: Filter numbers greater than 10
	for value := range filteredCh {     // Stage 4: Print the final output
		fmt.Printf("Value is %d\n", value)
	}
}

```

#### Code Flow Explanation

1. Stage Initialization:
    - Each stage is implemented as a function that takes an input channel and returns an output channel
    - Goroutines are used to execute each stage concurrently
1. Data Flow:
    - Data flows through the pipeline via channels
    - Each stage processes its input and sends results to the next stage
1. Termination:
    - Channels are closed when a stage finishes processing all input data (`defer close(out)`)
    - Closing channels signals downstream stages to stop reading
1. Final Output:
    - The final stage 4 consumes the filtered values from stage 3 and displays them


#### Best Practices When Coding
- Always close output channels when a stage finishes processing (`defer close(out)`)
- If stages have varying speeds, use buffered channels to prevent blocking fast producers or slow consumers
- Use a custom struct (e.g., `Result { Value int, Err error }`) to propagate errors through the pipeline without panicking
- Use `context.Context` or a `done` channel to signal goroutines to exit early during errors or shutdowns.
- Identify slow stages and parallelize them using Fan-Out/Fan-In patterns if needed
- Each stage should be designed as an isolated unit for easier testing and debugging

---