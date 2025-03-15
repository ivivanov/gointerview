+++
date = '2025-02-23T12:06:22+02:00'
draft = true
title = 'Misc'
slug = 'misc'
weight = 50
+++

## Questions?
1. When do you use WaitGroup?
1. What is errgroup package used for?
1. How do goroutines and channels help in leveraging multi-core systems? Provide practical examples.

TODOs:
1. What is deadlock. Can write an example of deadlock?
1. What is the difference between mutex and semaphore?
1. Explain how you would use a `sync.WaitGroup` to wait for multiple goroutines to finish.
1. How would you handle concurrent access to shared resources in Go?
2. Describe a scenario where you would choose channels over mutexes for synchronization.
3. How can you prevent race conditions when using goroutines?
4. What tools does Go provide for detecting race conditions in concurrent programs?

## Answers:

### 1. When do you use WaitGroup?
#### Use WaitGroup when:
- You need to wait for multiple goroutines to complete their execution before proceeding
- You have a known number of goroutines to wait for, typically in scenarios where you spawn many goroutines in a loop
- You don't need to communicate data between goroutines, just synchronize their completion

In some complex scenarios, you might use both WaitGroups and channels together to achieve more sophisticated synchronization and communication between goroutines.

When using sync.WaitGroup and channels in Go concurrency, there are some important best practices to follow:

#### Placement of wg.Add()
- Call wg.Add() before starting the goroutine, not inside it
- This prevents race conditions between wg.Add() and wg.Wait()
```go
wg.Add(1)
go func() {
    defer wg.Done()
    // Do work
}()
```

#### Counting Goroutines
- Use wg.Add(n) before a loop if you know the exact number of goroutines
- Or call wg.Add(1) for each iteration to be more flexible

#### Best Practices
- Use defer wg.Done() inside goroutines to ensure it's always called
- Consider using buffered channels when appropriate
- Use the -race flag when compiling to detect race conditions
- For complex scenarios, consider using worker pools or more advanced synchronization primitives

Remember, these practices help prevent common concurrency issues like race conditions and deadlocks in Go programs.
(A deadlock is a situation in concurrent programming where two or more processes or threads are unable to proceed because each is waiting for the other to release a resource, resulting in a circular dependency that prevents any of them from making progress.)

---

### 2. What is errgroup package used for?
The `golang.org/x/sync/errgroup` package is used to simplify the management of multiple goroutines working on subtasks of a common task. It extends the standard `sync.WaitGroup` by adding error handling and context cancellation capabilities. Here's a breakdown of its main features and use cases:

#### **Key Features**
1. **Error Propagation**:
   - Automatically propagates the first non-nil error returned by any goroutine in the group.
   - Cancels other running goroutines when an error occurs.

2. **Context Integration**:
   - Provides a derived `context.Context` when using `errgroup.WithContext`.
   - Cancels the context when any goroutine in the group returns an error or when `Wait` is called.

3. **Synchronization**:
   - Similar to `sync.WaitGroup`, it waits for all goroutines in the group to complete before proceeding.

4. **Concurrency Limiting**:
   - Allows setting a limit on the number of active goroutines using `SetLimit`, preventing resource exhaustion.

5. **Simplified Error Handling**:
   - Reduces boilerplate code for managing errors and synchronization in concurrent programming.

#### **Common Use Cases**
1. **Concurrent API Calls**:
   - Fetch data from multiple APIs in parallel and handle errors gracefully.
2. **Data Processing Pipelines**:
   - Process streams of data concurrently while ensuring proper error handling.
3. **Server Handlers**:
   - Parallelize tasks in HTTP handlers, such as querying multiple databases or services.
4. **Resource Management**:
   - Limit the number of concurrent operations to avoid overwhelming system resources.

#### **Basic Example**
```go
package main

import (
	"context"
	"fmt"
	"golang.org/x/sync/errgroup"
	"net/http"
)

func main() {
	g, ctx := errgroup.WithContext(context.Background())

	urls := []string{
		"https://golang.org",
		"https://google.com",
		"https://nonexistent.url",
	}

	for _, url := range urls {
		url := url // Capture loop variable
		g.Go(func() error {
			req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
			if err != nil {
				return err
			}
			resp, err := http.DefaultClient.Do(req)
			if err != nil {
				return fmt.Errorf("failed to fetch %s: %w", url, err)
			}
			defer resp.Body.Close()
			fmt.Printf("Fetched %s with status %s\n", url, resp.Status)
			return nil
		})
	}

	if err := g.Wait(); err != nil {
		fmt.Printf("Error: %v\n", err)
	} else {
		fmt.Println("Successfully fetched all URLs.")
	}
}
```

#### **Advanced Features**
1. **Concurrency Limiting**:
   ```go
   g.SetLimit(2) // Limit to 2 concurrent goroutines
   ```

2. **Using `TryGo`**:
   - Starts a goroutine only if it doesn't exceed the concurrency limit.
   ```go
   if g.TryGo(func() error { /* work */ }) {
       fmt.Println("Goroutine started")
   } else {
       fmt.Println("Concurrency limit reached")
   }
   ```

#### **Advantages Over `sync.WaitGroup`**
- Handles errors directly, unlike `sync.WaitGroup`, which requires additional logic for error tracking.
- Automatically cancels other goroutines on failure using context propagation.
- Provides concurrency control with `SetLimit`.


#### **Best Practices**
1. Always capture loop variables when launching goroutines inside loops (e.g., `url := url`).
2. Handle cancellation of the derived context (`ctx`) within your goroutines to ensure timely termination.
3. Use `errgroup` for tasks where error handling and cancellation are critical.

By using `errgroup`, you can write cleaner, more efficient, and robust concurrent code with streamlined error handling and synchronization.

---

### 3. How do goroutines and channels help in leveraging multi-core systems? Provide practical examples.

#### Parallel computation
Goroutines are lightweight threads managed by the Go runtime. They allow for concurrent execution and can be distributed across multiple CPU cores.

```go
func main() {
    numbers := []int{1, 2, 3, 4, 5, 6, 7, 8}
    results := make([]int, len(numbers))

    var wg sync.WaitGroup
    for i, num := range numbers {
        wg.Add(1)
        go func(i, num int) {
            defer wg.Done()
            results[i] = doWork(num)
        }(i, num)
    }
    wg.Wait()

    fmt.Println("Results:", results)
}

func doWork(n int) int {
    time.Sleep(100 * time.Millisecond)
    return n * n
}
```

This example distributes computations across multiple goroutines, potentially utilizing multiple CPU cores.

#### Channels
Channels facilitate communication and synchronization between goroutines, allowing for coordinated parallel processing.

```go
func main() {
    const numJobs = 100
    const numWorkers = 5

    jobs := make(chan int, numJobs)
	defer close(jobs)
    results := make(chan int, numJobs)
	defer close(results)

    // Start worker goroutines
    for w := 1; w <= numWorkers; w++ {
        go worker(w, jobs, results)
    }

    // Send jobs
    for j := 1; j <= numJobs; j++ {
        jobs <- j
    }

    // Collect results
    for a := 1; a <= numJobs; a++ {
        <-results
    }
}

func worker(id int, jobs <-chan int, results chan<- int) {
    for j := range jobs {
        fmt.Printf("Worker %d processing job %d\n", id, j)
        time.Sleep(time.Millisecond) // Simulate work
        results <- j * 2
    }
}
```

This worker pool example demonstrates how channels can distribute work across multiple goroutines, efficiently utilizing multi-core systems.

By using goroutines and channels, Go programs can effectively parallelize tasks, improving performance on multi-core systems while maintaining clear and manageable code structure.

---
