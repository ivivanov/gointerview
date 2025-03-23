+++
date = '2025-03-07T15:41:30+02:00'
draft = true
title = 'Patterns'
slug = 'patterns'
weight = 40
+++

## Questions?
1. What concurrency design patterns are you familiar with?
1. Worker Pool
1. Fan-Out/Fan-In
1. Producer-Consumer
1. Pipeline
1. Generator
1. Multiplexing
1. Timeout
1. Quit Signal
1. Bounded Parallelism
1. Context
1. Semaphore

## Answers:

### 1. What concurrency design patterns are you familiar with?
- ***Worker Pool:*** Managing task execution across multiple goroutines
- ***Fan-Out/Fan-In:*** Distributing tasks and collecting results
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

#### Common Use Cases
- Batch processing large datasets
- Handling API rate limits
- Image/video processing pipelines
- Database operation queues
- Concurrent network requests

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
4. After all jobs complete:
   - Workers exit via closed jobs channel
   - Results channel closes
5. Main collects and prints results.
    - `sync.WaitGroup` ensures main waits for worker completion
    - Closing channels signals completion:
        - `close(jobs)` triggers worker exit
        - `close(results)` enables safe result collection

#### Best Practices
- Always close channels from the sender side
- Use WaitGroups for proper synchronization
- Size buffers appropriately for workload
- Handle errors and timeouts in production code
- Use context cancellation for complex shutdown scenarios


---

### 3. Fan-Out/Fan-In

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
- ***Scalability:*** Easily adjust worker count to match workload demands.
- ***Decoupled components:*** Workers operate independently, improving fault isolation.
- ***Order-agnostic processing:*** Ideal for tasks where result order doesn't matter.
- ***Cost efficiency:*** Reduces cloud costs via optimized resource usage (e.g., AWS Lambda parallel invocations).

#### Common Use Cases
- Real-time data processing (IoT sensor streams)
- Bulk image/video transcoding
- Distributed web scraping
- Concurrent API request handling
- Log aggregation from multiple sources
- ETL (Extract-Transform-Load) pipelines

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
1. **Initialization**:
   - Create buffered channels for jobs and results
   - Initialize WaitGroup for worker synchronization

2. **Fan-Out Phase**:
   ```go
   for w := 1; w <= numWorkers; w++ {
       wg.Add(1)
       go worker(w, jobs, results, &wg)
   }
   ```
   - Launch worker goroutines that pull from `jobs` channel
   - Each worker processes jobs concurrently

3. **Job Distribution**:
   ```go
   go func() {
       for j := 1; j <= numJobs; j++ {
           jobs <- j
       }
       close(jobs) // Signal no more jobs
   }()
   ```
   - Feed jobs to workers via channel
   - Close channel when done to trigger worker exit

4. **Fan-In Phase**:
   ```go
   go func() {
       wg.Wait()    // Block until all workers finish
       close(results)
   }()
   ```
   - Close results channel after all workers complete
   - Enables clean exit from results loop

5. **Result Aggregation**:
   ```go
   for result := range results {
       fmt.Printf("Result: %d\n", result)
   }
   ```
   - Main thread processes combined outputs

---

#### Best Practices
1. Channel Management:
   - Use buffered channels matching workload size
   - Always close channels from the sender side
   ```go
   defer close(results) // In worker after processing
   ```

2. Worker Configuration:
   - Set worker count using `runtime.NumCPU()` for CPU-bound tasks
   - Use exponential backoff for I/O-bound operations

3. Error Handling:
   ```go
   results <- Result{value: res, err: err}
   // In main loop:
   if result.err != nil {
       // Handle error
   }
   ```

4. Context Integration:
   ```go
   ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
   defer cancel()
   
   select {
   case jobs <- data:
   case <-ctx.Done():
       return ctx.Err()
   }
   ```

5. Monitoring:
   - Track channel buffer levels
   - Implement worker health checks
   - Use prometheus metrics for queue depth monitoring

6. Graceful Shutdown:
   ```go
   sig := make(chan os.Signal, 1)
   signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)
   <-sig // Wait for shutdown signal
   cancel() // Propagate cancellation
   ```

---

### 4. Producer-Consumer

---

### 5. Pipeline

---

### 6. Generator

---

### 7. Multiplexing

---

### 8. Timeout

---

### 9. Quit Signal

---

### 10. Bounded Parallelism

---

### 11. Context

---

### 12. Semaphore

---




explain me Fan-Out/Fan-In pattern in the following structured order:
1. Problems Solved by the pattern
2. Key Advantages
3. Common Use Cases
4. code example
5. Code flow explanation
6. best practices when coding 