+++
date = '2025-03-07T15:41:30+02:00'
draft = true
title = 'Patterns'
slug = 'patterns'
weight = 40
+++

## Questions?

1. Worker Pool: Managing task execution across multiple goroutines
2. Fan-Out/Fan-In: Distributing tasks and collecting results
3. Pipeline: Processing data in stages
4. Generator: Functions that return channels
5. Multiplexing: Combining multiple channels
6. Timeout: Adding time limits to goroutine execution
7. Quit Signal: Gracefully stopping goroutines
8. Bounded Parallelism: Limiting concurrent execution
9. Context: Managing cancellation and deadlines across goroutines
10. Semaphore: Controlling access to shared resources


1. What concurrency design patterns are you familiar with?
1. Explain the producer-consumer pattern using goroutines and channels.
1. How would you implement a worker pool in Go?
1. What is the purpose of the `select` statement in Go, and how is it used with channels?
1. How can you implement timeouts for goroutines using channels?

## Answers:


---
### 1. How would you close gracefully a channel with multiple senders?
### 5. How would you implement graceful shutdown of multiple goroutines?
To implement graceful shutdown of multiple goroutines in Go, follow this structured approach using context cancellation and synchronization primitives:

#### **Implementation Steps**

1. **Set Up Signal Handling**  
   Capture OS signals (e.g., `SIGINT`, `SIGTERM`) to initiate shutdown.

2. **Create Context and WaitGroup**  
   Use a cancellable context and `sync.WaitGroup` to track goroutines.

3. **Start Goroutines**  
   Design workers to respond to context cancellation and decrement the `WaitGroup`.

4. **Shutdown Logic**  
   Cancel the context on shutdown signal and wait for goroutines to exit with a timeout.

---

#### **Example Code**
```go
package main

import (
    "context"
    "fmt"
    "os"
    "os/signal"
    "sync"
    "syscall"
    "time"
)

func worker(ctx context.Context, wg *sync.WaitGroup, id int) {
    defer wg.Done()
    for {
        select {
        case <-ctx.Done(): // Triggered on shutdown
            fmt.Printf("Worker %d: Shutting down\n", id)
            return
        default:
            // Simulate work (e.g., processing tasks)
            fmt.Printf("Worker %d: Working\n", id)
            time.Sleep(1 * time.Second)
        }
    }
}

func main() {
    ctx, cancel := context.WithCancel(context.Background())
    var wg sync.WaitGroup

    // Start 5 workers
    const numWorkers = 5
    for i := 0; i < numWorkers; i++ {
        wg.Add(1)
        go worker(ctx, &wg, i)
    }

    // Capture OS signals for graceful shutdown
    stop := make(chan os.Signal, 1)
    signal.Notify(stop, os.Interrupt, syscall.SIGTERM)

    // Block until shutdown signal received
    <-stop
    fmt.Println("\nShutting down...")

    // Step 1: Cancel context to notify workers
    cancel()

    // Step 2: Wait for workers to finish (with timeout)
    done := make(chan struct{})
    go func() {
        wg.Wait()       // Wait for all workers to exit
        close(done)
    }()

    select {
    case <-done:
        fmt.Println("All workers exited")
    case <-time.After(5 * time.Second):
        fmt.Println("Timeout: Some workers may still be running")
    }

    // Cleanup resources (e.g., close databases)
    fmt.Println("Exiting gracefully")
}
```

---

#### **Key Components**
| **Component**          | **Purpose**                                                                 |
|-------------------------|-----------------------------------------------------------------------------|
| `context.Context`       | Propagates cancellation signals to all goroutines.                         |
| `sync.WaitGroup`        | Tracks active goroutines and waits for completion.                         |
| `signal.Notify`         | Listens for OS signals (e.g., `Ctrl+C`) to trigger shutdown.               |
| `select` with Timeout   | Ensures the program doesn’t hang indefinitely during shutdown.             |

---

#### **Best Practices**
1. **Use Context Hierarchies**  
   Derive child contexts for subtasks to ensure cascading cancellation.
   ```go
   childCtx, cancelChild := context.WithCancel(ctx)
   defer cancelChild()
   ```

2. **Handle Blocking Operations**  
   Use `select` to listen for `ctx.Done()` in blocking I/O:
   ```go
   select {
   case <-ctx.Done():
       return ctx.Err()
   case data := <-inputChan:
       process(data)
   }
   ```

3. **Graceful Resource Cleanup**  
   Close databases, files, or network connections after all goroutines exit:
   ```go
   defer db.Close() // After wg.Wait()
   ```

4. **Logging**  
   Track shutdown progress and errors for observability:
   ```go
   log.Printf("Worker %d: Exited cleanly", id)
   ```

---

#### **Common Pitfalls**
1. **Goroutine Leaks**  
   Ensure all goroutines check `ctx.Done()` or a shutdown channel to avoid leaks.

2. **Race Conditions**  
   Use `sync/atomic` or mutexes if workers share state.

3. **Timeout Too Short**  
   Choose a timeout that allows in-flight requests to complete (e.g., 10-30 seconds).

---

#### **Alternative Approach: Channel-Based Shutdown**
For simpler cases, use a channel to broadcast shutdown:
```go
shutdown := make(chan struct{})

// In workers
select {
case <-shutdown:
    return
default:
    // Work
}

// Trigger shutdown
close(shutdown)
```

---
