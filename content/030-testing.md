+++
date = '2025-02-28T15:49:40+02:00'
draft = false
title = 'Testing'
slug = 'testing'
weight = 30
+++

## Questions?
1. What are some best practices for writing unit tests in Go? 
1. Explain how to use table-driven tests in Go with an example.
1. What is mocking and how do you handle it? Give an example.
1. What is the difference between mock and stub?

## Answers:

### 1. What are some best practices for writing unit tests in Go?
By following these practices, you can create more effective, maintainable, and comprehensive unit tests in Go:
- ***Naming convention***:
	- ***Group tests by functionality:*** Organize test cases based on features or modules
	- ***Structure your tests properly:*** Include a clear title, preconditions, steps, and expected results for each test case
	- ***Write clear and concise test cases:*** Ensure your tests have straightforward steps and expected results
	- Basic function tests:
		```go
		TestParseJSON
		TestCalculateTotal
		TestEncryptPassword
		TestGenerateUUID
		```
	- Specific scenario tests:
		```go
		TestValidateEmail_EmptyString_ShouldFail
		TestValidateEmail_MissingAt_ShouldFail
		TestValidateEmail_Success
		```
	For more info check [Go’s testing documentation](https://pkg.go.dev/testing)

- ***Use table-driven tests:*** This approach allows you to run the same test logic with different inputs and expected outputs, making tests more thorough and organized
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

### 3. What is mocking and how do you handle it? Give an example.
Mocking is a technique used in software testing to create simulated objects that mimic the behavior of real objects. In Go, mocking is particularly useful for isolating units of code during testing and simulating dependencies. To handle mocking in Go:

- ***Use interfaces:*** Define interfaces for your dependencies to make them easier to mock
- ***Mocking libraries:*** Tools like GoMock can automate the creation of mock objects, reducing boilerplate code
- ***Use constructor injection:*** This makes it easier to inject mocks during testing while using real implementations in production
- ***Focus on behavior, not implementation:*** Write tests that verify expected outcomes rather than specific method call sequences
- ***Use built-in matchers:*** Take advantage of matchers provided by mocking libraries to make tests more flexible
- ***Clean up after tests:*** Use `defer ctrl.Finish()` to ensure proper cleanup of mock objects

#### Example:

Let's create example in which we:
1. Define `UserRepository` interface
2. Create a mock of that interface
3. Setup up expectations on the mock
4. Use the mock in a test to verify behavior

By using mocks, we can test the `UserService` without needing a real database or API, making our tests faster and more isolated.

First, let's define an interface:

```go
// user.go
package user

type UserRepository interface {
    GetUser(id int) (string, error)
}
```

Now, let's create a service that uses this interface:

```go
// service.go
package user

type UserService struct {
    repo UserRepository
}

func (s *UserService) GetUserName(id int) (string, error) {
    return s.repo.GetUser(id)
}
```

To test this service, we'll generate a mock:

```bash
go get -u go.uber.org/mock
go install go.uber.org/mock/mockgen@latest
mockgen -source=user/user.go -destination=user/mocks/mock_userRepository.go -package=mocks
```

Now, let's write a test using this mock:

```go
// service_test.go
package user

func TestGetUserName(t *testing.T) {
	for _, tt := range []struct {
		name     string
		id       int
		expected string
		err      error
	}{
		{"successful getting user", 1, "Alice", nil},
		{"invalid ID should return error", 2, "", errors.New("user not found")},
	} {
		t.Run(tt.name, func(t *testing.T) {
			ctrl := gomock.NewController(t)
			defer ctrl.Finish()

			mockRepo := mocks.NewMockUserRepository(ctrl)
			service := &UserService{repo: mockRepo}

			mockRepo.EXPECT().GetUser(tt.id).Return(tt.expected, tt.err)

			name, err := service.GetUserName(tt.id)
			if err != tt.err || name != tt.expected {
				t.Errorf("Expected %s, got %s with error %v", tt.expected, name, err)
			}
		})
	}
}
```

---

### 4. What is the difference between mock and stub?
Mocks and stubs are both test doubles used in software testing, but they serve different purposes and have distinct characteristics:

1. Purpose:
   - Mocks are used to verify behavior and interactions between objects.
   - Stubs are used to provide predetermined responses to method calls, focusing on state verification

2. Functionality:
   - Mocks can be programmed to expect specific method calls, arguments, and call order
   - Stubs provide consistent, predefined responses to method calls without verifying interactions

3. Verification:
   - Mocks allow you to verify whether specific interactions have occurred during the test
   - Stubs focus on returning predefined data and don't verify interactions

4. Complexity:
   - Mocks are generally more complex and suitable for testing intricate systems with multiple dependencies
   - Stubs are simpler and often used for testing isolated units with minimal dependencies

5. Usage:
   - Mocks are typically used when you want to ensure correct interactions between objects
   - Stubs are used when you need to control the output of dependencies to create specific test scenarios

6. Test focus:
   - Mocks focus on behavior verification, ensuring methods are called correctly
   - Stubs focus on state verification, providing consistent results for testing

7. Flexibility:
   - Mocks offer greater flexibility for specifying expected behavior and interactions
   - Stubs are more static, providing predictable responses

In summary, use stubs for simple tests focusing on functionality and state, and use mocks for more complex tests requiring behavior verification and interaction checking.

---
