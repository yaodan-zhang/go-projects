[ctoss![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-24ddc0f5d75046c5622901739e7c5dd533143b0c8e959d652212380cedb1ea36.svg)](https://classroom.github.com/a/J09Bd3iG)

# Project \#2: A Simple Twitter Client/Server System

**See gradescope for due date**

This project is intended to make you practice the use and implementation
of parallel data structures using low-level primitives.

> **Note**:
> There will be aspects of this assignment that are not the most efficient
> way to implement various components. It will be your job at the end of
> this assignment to analyze the implementation of this project and think
> about how components can be improved or aspects removed to speedup
> performance. Keep this in mind while working on this project.

## Assignment: Single-User Twitter Feed

For this assignment you are **only** allowed to use the following Go
concurrent constructs:

- `go` statement
- `sync.Mutex` and its associated methods.
- `sync/atomic` package. You may use any of the atomic operations.
- `sync.WaitGroup` and its associated methods.
- `sync.Cond` and its associated methods.

You **cannot** use Go channels (i.e., `chan`) or anything related to
channels in this assignment\! **If you are unsure about whether you are
able to use a language feature then please ask on Slack before using it**.

## Part 1: Twitter Feed

A disgruntled Twitter staff member deleted important software from the
servers on their last day at work. You were hired to help restore
services, by re-developing the data structure that represents a user's
feed. Your implementation will redefine it as a singly linked list.

Your task to implement the remaining incomplete methods of a `feed`
(i.e. the `Add`, `Remove`, and `Contains` methods). You must use the
internal representations for `type feed struct` and `type post struct`
in your implementation. **Do not implement a parallel version of the
linked list at this point**. You can only add fields to the struct but
cannot modify the original fields given.

Test your implementation of feed by using the test file called
`feed_test.go`. You should only run the sequential tests first:

- `TestSimpleSeq`
- `TestAdd`
- `TestContains`
- `TestRemove`

As a reminder from prior assignments, you can run individual tests by
using the `-run` flag when using `go test`. This flag takes in a regular
expression to know which tests to run. Make sure are you in the
directory that has the `*_test.go` file.

Sample run of the `SimpleSeq` test:

    //Run top-level tests matching "SimpleSeq", such as "TestSimpleSeq".
    $ go test -run "SimpleSeq"
    PASS
    ok    hw4/feed    0.078s

Sample run of the `SimpleSeq` and `TestAdd` tests:

    //Run top-level tests matching "SimpleSeq" such as "TestSimpleSeq" and "TestAdd".
    $ go test -v -run "SimpleSeq|TestAdd"
    === RUN   TestSimpleSeq
    --- PASS: TestSimpleSeq (0.00s)
    === RUN   TestAdd
    --- PASS: TestAdd (0.00s)
    PASS
    ok    hw4/feed    0.078s

You can also run specific tests by using anchors. For example to run
only `TestAdd` then execute the following command:

    $ go test -v -run ^TestAdd$
    === RUN   TestAdd
    --- PASS: TestAdd (0.00s)
    PASS
    ok      hw4/feed      0.103s

## Part 2: Thread Safety using a Read-Write Lock

A read/write lock mechanism allows multiple readers to access a data
structure concurrently, but only a single writer is allowed to access
the data structures at a time. Implement a read/write lock library that
**only** uses a **single condition variable** and **mutex** for its
synchronization mechanisms. Go provides a Read/Write lock that is
implemented using atomics:

- [R/W Mutex in Go](https://golang.org/pkg/sync/#RWMutex)

As with the Go implementation, you will need to provide four methods
associated with your lock:

- `Lock()`
- `Unlock()`
- `RLock()`
- `RUnlock()`

These methods should function exactly like their Go counterparts.
Documentation on each method's functionality is described by the link
provided above. You **must** limit the max number of readers to `32`.

### Coarse Grain Feed

Now, go back to your feed library inside of `feed.go` and make it
thread-safe by using your implementation of a read/write lock. You need
to think about the appropriate places to call the various read/write
locking and unlocking methods in the `feed` methods. **This must be a
coarse grain implementation**. Test that this is working by running the
remaining tests inside the `feed_test.go` file.

Helpful Resource(s):

- [Condition Variables in
  Go](https://kaviraj.me/understanding-condition-variable-in-go/)

## Part 3: A Twitter Server

Using the `feed` library from Part 1, you will implement a server that
processes **requests**, which perform actions (e.g., add a post, remove
a post, etc.) on a single feed. These requests come from a client
program (e.g., the twitter mobile app) where a user can request to
modify their feed. The server sends **responses** back to the client
with a result (e.g., notification that a post was added and/or removed
successfully, etc.).

The client and server must agree on the format to send the requests and
responses. One common format is to use JSON, which you have used in the
previous project. For our server, requests
and responses are single strings in the JSON format.

**Make sure you fully understand the “Streaming Encoders and Decoders”
section. You'll be using encoders and decoders in this part heavily**.

The client and server will need to use decoders and encoders to parse
the JSON string into a type easily usable in Go. You will use the
`json.Decoder`, which acts as a streaming buffer of requests, and
`json.Encoder`, which acts as a streaming buffer of responses. This
model is a simplified version of a real-life client-server model used
heavily in many domains such as web development. At a high-level, you
can think of your program as a simple “server” in the client-server
model illustrated below:

![image](./cs_model.png)

Requests (i.e., tasks in our program) are sent from a “client” (e.g., a
redirected file on the command line, a task generator program piped into
your program, etc.) via os.Stdin. The “server” (i.e., your program) will
process these requests and send their results back to the client via
os.Stdout. This model is a mimicking a real-life client-server model
used heavily in many domains such as web development; however, we are
not actually implementing web client-server system in this assignment.

### Requests and Responses Format

The basic format for the requests coming in from `json.Decoder` will be
of the following format:

```json
{ 
"command": string, 
"id": integer, 
... data key-value pairings ... 
}
```

A request will always have a `"command"` and `"id"` key. The `"command"`
key holds a string value that represents the type of feed task. The
`"id"` represents an unique identification number for this request.
Requests are processed asynchronously by the server so requests can be
processed out of order from how they are received from `json.Decoder`;
therefore, the `"id"` acts as a way to tell the client that result
coming back from the server is a response to an original request with
this specific `"id"` value. Thus, **it is not your responsibility to
maintain this order and you must not do anything to maintain it in your
program**.

The remaining key-value pairings represent the data for a specific
request. The following subsections will go over the various types of
requests.

### Add Request

An add request adds a new post to the feed data structure. The
`"command"` value will always be the string `"ADD"`. The data fields
include a key-value pairing for the message body (`"body": string`) and
timestamp (`"timestamp": number`). For example,

```json
{ 
  "command": "ADD", 
  "id": 342, 
  "body": "just setting up my twttr", 
  "timestamp": 43242423
}
```

After completing a `"ADD"` request, the goroutine assigned the request
will send a response back to the client via `json.Encoder` acknowledging
the add was successful. The response is a JSON object that includes a
success key-value pair (`"success": boolean`). For an add request, the
value is always true since you can add an infinite number of posts. The
original identification number should also be included in the response.
For example, using the add request shown above, the response message is

```json
{ 
  "success": true, 
  "id": 342
}
```

### Remove Request

A remove request removes a post from the feed data structure. The
`"command"` value will always be the string `"REMOVE"`. The data fields
include a key-value pairing for the timestamp (`"timestamp": number`)
that represents the post that should be removed. For example,

```json
{ 
  "command": "REMOVE", 
  "id": 2361, 
  "timestamp": 43242423
}
```

After completing a `"REMOVE"` task, the goroutine assigned the task will
send a response back to the client via `json.Encoder` acknowledging the
remove was successful or unsuccessful. The response is a JSON object
that includes a success key-value pair (`"success": boolean`). For a
remove request, the value is `true` if the post with the requested
timestamp was removed, otherwise assign the key to `false`. The original
identification number should also be included in the response. For
example, using the remove request shown above, the response message is

```json
{ 
  "success": true, 
  "id": 2361
}
```

### Contains Request

A contains request checks to see if a feed post is inside the feed data
structure. The `"command"` value will always be the string `"CONTAINS"`.
The data fields include a key-value pairing for the timestamp
(`"timestamp": number`) that represents the post to check. For example,

```json
{ 
  "command": "CONTAINS", 
  "id": 2362, 
  "timestamp": 43242423
}
```

After completing a `"CONTAINS"` task, the goroutine assigned the task
will send a response back to the client via `json.Encoder` acknowledging
whether the feed contains that post. The response is a JSON object that
includes a success key-value pair (`"success": boolean`). For a contains
request, the value is `true` if the post with the requested timestamp is
inside the feed, otherwise assign the key to `false`. The original
identification number should also be included in the response. For
example, using the contains request shown above, the response message is

```json
{ 
  "success": false, 
  "id": 2362
}
```

**Note**: Assuming we removed the post previously.

### Feed Request

A feed request returns all the posts within the feed. The `"command"`
value will always be the string `"FEED"`. Their are no data fields for
this request. For example,

```json
{ 
  "command": "FEED", 
  "id": 2, 
}
```

After completing a `"FEED"` task, the goroutine assigned the task will
send a response back to the client via `json.Encoder` with all the posts
currently in the feed. The response is a JSON object that includes a
success key-value pair (`"feed": [objects]`). For a feed request, the
value is a JSON array that includes a JSON object for each feed post.
Each JSON object will include a `"body"` key (`"body": string`) that
represents a post’s body and a `"timestamp"` key (`"timestamp": number`)
that represents the timestamp for the post. The original identification
number should also be included in the response. For example, assuming we
inserted a few posts into the feed, the response should look like

```json
{ 
  "id": 2,
  "feed":[
        { 
          "body": "This is my second twitter post", 
          "timestamp": 43242423
        },
        {
          "body": "This is my first twitter post", 
          "timestamp": 43242420
        }
        ]
}
```

### Done Request

If client will no longer send requests then it sends a done request. The
`"command"` value will always be the string `"DONE"`. Their are no data
fields for this request. For example,

```json
{ 
  "command": "DONE" 
}
```

This notifies server it needs to *shutdown* (i.e., close down the
program). A done request signals to the main goroutine that no further
processing is necessary after this request is received. No response is
sent back to the client. Make sure to handle all remaining requests in
the and responses before shutting down the program.

### Implementing the Server

Inside the `server/server.go` file, you will see the following code,

```go
type Config struct {
  Encoder *json.Encoder // Represents the buffer to encode Responses
  Decoder *json.Decoder // Represents the buffer to decode Requests
  Mode    string        // Represents whether the server should execute
                        // sequentially or in parallel
                        // If Mode == "s"  then run the sequential version
                        // If Mode == "p" then run the parallel version 
                        // These are the only values for Version
  ConsumersCount int    // Represents the number of consumers to spawn
}

//Run starts up the twitter server based on the configuration
//information provided and only returns when the server is fully
// shutdown.
func Run(config Config) {
  panic("TODO")

}
```

When a goroutine calls the `Run` function, it will start the server
based on the configuration passed to the function. Read over the
documentation above to understand the members of the configuration
struct. This function does not return (i.e., it is a blocking function)
until the server is shutdown (i.e., it receives the `"DONE"` request).
You must not modify the `Config` struct or the function header for the
`Run` function because the tests rely on this structure. The following
sections explain the modes of the server.

### Parallel Version: Tasks Queue

Inside the `Run` function, if `config.Mode == "p"` then the server will
run the parallel version. This version is implemented using a *task
queue*. This task queue is another work distribution technique and your
first exposure to the producer-consumer model. In this model, the
producer will be the main goroutine and its job is to collect a series
of tasks and place them in a queue structure to be executed by consumers
(also known as workers). The consumers will be spawned goroutines. You
**must** implement the parallelization as follows:

1. The main goroutine begins by spawning a specified
   `config.ConsumersCount` goroutines, where each will begin executing
   a function called `func consumer(...)`. It is up to you to decide
   the arguments you pass to this function. Each goroutine will either
   begin doing work or go to sleep in a conditional wait if there is no
   work to begin processing yet. This “work” is explained in Steps 3
   and 4. **Your program cannot spawn additional goroutines after this
   initial spawning by the main goroutine**.
2. After spawning the consumer goroutines, the main goroutine will call
   a function `func producer(...)`. Again, what you pass to this
   function is for you to decide. Inside the producer function, the
   main goroutine reads in from `json.Decoder` a series of tasks (i.e.,
   requests). For the sake of explicitness, the tasks will be feed
   operations for a single user-feed that the program manages. The main
   goroutine will place the tasks inside of a queue data structure and
   do the following:
   - If there is a consumer goroutine waiting for work then place a
     task inside the queue and wake one consumer up.
   - Otherwise, the main gorountine continues to place tasks into the
     queue. Eventually, the consumers will grab the tasks from the
     queue at later point in time.
3. Inside the `func consumer(...)` function each consumer goroutine
   will try to grab one task from the queue. The consumer will then
   process the request and send the appropriate response back. When a
   consumer finishes executing its task, it checks the queue to grab
   another task. If there are no tasks in the queue then it will need
   to wait for more tasks to process or exit its function if there are
   no remaining tasks to complete.

### Additional Queue Requirements

You must implement this queue data structure so that both the main and
worker goroutines have access to retrieve and modify it. All work is
placed in this queue so workers can grab tasks when necessary. Along
with the requirements defined in this section, the actual enqueuing and
dequeuing of items must also be done in a unbounded lock-free manner
(i.e., non-blocking). However, the code to make the producer signal to
consumers, and consumers to wait on work must be done using a condition
variable. No busy waiting is allowed in this assignment.

You may want to separate out the queue implementation into its own
package and then have `server.go` import it. This design is up to you.
However, the producer and consumer functions must always remain in
`server.go`. I will also allow you to separate out the producer/consumer
condition variable code from the unbounded lock-free queue code. Again,
this is for you to decide.

### Sequential Version

You will need to write a sequential version of this program where the
main goroutine processes and executes all the requested tasks without
spawning any gorountines.

## Part 4: The Twitter Client

Inside the `twitter/twitter.go`, you must define a simple Twitter client
that has the following usage and required command-line argument:

```
Usage: twitter <number of consumers>
    <number of consumers> = the number of goroutines (i.e., consumers) to be part of the parallel version.  
```

The program needs to create a `server.Config` value based off the above
arguments. If `<number of consumers>` is not entered then this means you
need to run your sequential version of the server; otherwise, run the
parallel version. The `json.Decoder` and `json.Encoder` should be
created by using `os.Stdin` and `os.Stdout`. Please refer back to the
“Streaming Encoders and Decoders” section here: [JSON in
Go](https://blog.golang.org/json). The last call in the main function is
to start running the server. Once the `Run` function returns than the
program exits. Don't over think this implementation. It should be simple
and short.

Assumptions: No error checking is needed. All tasks read-in will be in
the correct format with all its specified data. All command line
arguments will be given as specified. You will not need to printout the
usage statement. This is shown for clarity purposes.

### Sample Files/Test Cases

You may want to create a few sample files with a few tasks within them
(all on separate lines). For example, you could create a file called
tasks.txt with the following contents:

    {"command": "ADD", "id": 1, "body": "just setting up my twttr", "timestamp": 43242423}
    {"command": "ADD", "id": 2, "body": "Another post to add", "timestamp": 43242421}
    {"command": "REMOVE", "id": 3, "timestamp": 43242423}
    {"command": "DONE"}

You could then use file redirection to supply those files to your
twitter program as such:

    $ go run twitter.go 2 < tasks.txt

Note you are not reading from a file in this assignment\! You are using
file redirection that is part of terminal to supply `os.Stdin` with the
contents of the file specified on the command line.

## Part 5: Benchmarking Performance

In Part 5, you will test the execution time of your parallel
implementation by averaging the elapsed time of the twitter tests. You
are required to run the timings on a CS cluster, details are on Canvas.

### Grading for Part \#5

**An "A" grade for this project requires a high performing solution**;
therefore, the breakdown for grading part 5 is as follows:

- **Full points (10 points)**: You must complete the following two
  requirements to get full points:
  1. You must pass all tests (i.e., by running `go run proj2/grader proj2`).
  2. The elapsed time for a single run of the tests inside `twitter`
     directory (`go test -v` in `proj2/twitter`) in seconds must be
     below 150s, referred to as the "fast" threshold. The
     elapsed time is shown as the last line produced by the tests
     cases:

     PASS
     ok      proj2/twitter   103.976s

     Only use the ``benchmark-proj2.sh`` script for testing. This file only has the single line ``go test proj2/twitter -v -count=1`` but when grading we will run the tests 5 times and consider the average time when running it using the ``--exclusive`` flag.
- **Partial points (5 points)**: You must complete the following two
  requirements to get partial credit:
  1. You must pass all tests (i.e., by running `go run proj2/grader proj2`).
  2. The elapsed time for a single run of the tests inside `twitter`
     directory (`go test -v` in `proj2/twitter`) in seconds must be
     below the "slow" threshold of 180s.
- **No points (0 points)**: No points will be given for this part to
  solutions that do not pass all tests by running `go run proj2/grader proj2` and/or exceed the "slow" threshold for a single run of the
  tests inside `twitter` directory (`go test -v` in `proj2/twitter`).

## Part 6: Performance Measurement

Inside the `proj2/benchmark` directory, you will see the a file called
`benchmark.go`. This program copies over the all requests test cases you
saw from `twitter/twitter_test.go`(i.e., extra-small, small, medium,
large, and extra-large). The benchmark program allows you to execute one
of these test cases using your sequential or parallel versions and
outputs the elapsed time for executing that test. Please read over the
usage statement for this program to understand how to use it:

    Usage: benchmark version testSize threads
    version =  (p) - parallel version, (s) sequential version
    testSize = Any of the following commands can be used for the testSize argument
    xsmall = Run the extra small test size
            small = Run the small test size
            medium = Run the  medium test size
            large = Run the large test size
            xlarge = Run the extra large test size
    threads (required for p version only) = the number of threads to pass to twitter.go

Sample Runs

Here's how to run your sequential version on the extra-small test case:

    $: go run benchmark.go s xsmall
    0.27

The only output is the execution time (in seconds) to run the extra
small test.

Here's how to run your parallel version on the medium test case with 4
threads:

    $: go run benchmark.go p medium 4
    0.95

Notice that you only need to specify these arguments after the test
command (i.e., `medium`) when running the parallel version. The
additional arguments are the number of threads.

Play around with running the benchmark program before moving on to the
next subsection.

### Generation of speedup graphs

We will use the `benchmark.go` program to produce a speedup graph for
the different test-cases by varying the number of threads. The set of
threads will be `{2,4,6,8,12}`. You must run
each line execution 5 times in a row. Here are a few notes about the
speedup graph:

1. For example, running the xsmall line for threads =2:

   $ go run benchmark.go p xsmall 2
   0.30
   $ go run benchmark.go p xsmall 2
   0.27
   $ go run benchmark.go p xsmall 2
   0.27
   $ go run benchmark.go p xsmall 2
   0.26
   $ go run benchmark.go p xsmall 2
   0.27

   and use the average time (0.274) to use for the speedup calculation,
   which again is

   > \[Speedup = \frac{\text{wall-clock time of serial execution}}{\text{wall-clock time of parallel execution}}\]
   >

   You may or may not have speedups for all lines and the speedups may
   vary from thread to thread. Your lines may just look odd and that's
   all okay. You will analyze these graphs in the next part.
2. For the speedup graph, the y-axis will list the speedup measurement
   and the x-axis will list the number of threads. Similar to the graph
   shown below. Make make sure to title the graph, and label each axis.
   Make sure to adjust your y-axis range so that we can accurately see
   the values. That is, if most of your values fall between a range of
   \[0,1\] then don't make your speedup range \[0,14\].
3. You must write a script that produces the graph on the cluster.
4. All your work for this section must be placed in the `benchmark`
   directory along with the generated speedup graphs.

> **Note**:
> You do not have to use the elapsed time provided by the benchmark
> program. You can still use `time` or if you are using Python some other
> mechanism such as `timeit`. You must be consistent with your choice of a
> timing mechanism. This means you cannot use the elapsed time from the
> benchmark program for one sample run and then other timing mechanism for
> other sample runs. This is not a stable timing environment so you must
> stick with the same mechanism for producing all graphs.

## Part 7: Performance Analysis

Please submit a report (pdf document, text file, etc.) summarizing your
results from the experiments and the conclusions you draw from them.
Your report should **also** include the graph as specified above and an
analysis of the graph. That is, somebody should be able to read the
report alone and understand what code you developed, what experiments
you ran and how the data supports the conclusions you draw. The report
**must** also include the following:

- A brief description of the project (i.e., an explanation what you
  implemented in feed.go, server.go, twitter.go. A paragraph or two
  recap will suffice.
- Instructions on how to run your testing script. We should be able to
  just run your script. However, if we need to do another step then
  please let us know in the report.
- - As stated previously, you need to explain the results of your
    graph. Based on your implementation why are you getting those
    results? Answers the following questions:

    - What affect does the linked-list implementation have on
      performance? Does changing the implementation to lock-free
      or lazy-list algorithm size improve performance? Experiment
      with this by substituting your lazy-list implementation from
      homework 4. You should only need to make a few modifications
      to make this work.
    - Based on the topics we discussed in class, identify the
      areas in your implementation that could hypothetically see
      increases in performance if you were to use a different
      synchronization technique or improved queuing techniques.
      Specifically, look at the RW lock, queue, and
      producer/consumer components and how they all might be
      affecting performance. Explain why you would see potential
      improvements in performance based on either keeping these
      components or substituting them out for better algorithms.
    - Does the hardware have any affect on the performance of the
      benchmarks?

Place your report inside the `proj2/benchmark` directory with the name
`proj2_report.pdf`. Make sure to include your speedup graph in the
report.

## Grading

Programming assignments will be graded according to a general rubric.
Specifically, we will assign points for completeness, correctness,
design, and style. (For more details on the categories, see our
[Assignment Rubric page](../index.html).)

The exact weights for each category will vary from one assignment to
another. For this assignment, the weights will be:

- **Completeness:** 50%
- **Correctness:** 15%
- **Design & Style:** 10%
- **Performance:** 10%
- **Analysis Report:** 15%

### Obtaining your test score

The completeness part of your score will be determined using automated
tests. To get your score for the automated tests, simply run the
following from the **Terminal**. (Remember to leave out the `$` prompt
when you type the command.)

    $ cd grader
    $ go run proj2/grader proj2

This should print total score after running all test cases inside the
individual problems. This printout will not show the tests you failed.
You must run the problem's individual test file to see the failures.

Your actual completeness score will come from running the grader on the
CS cluster manually by the graders. We have provided a slurm script
inside `grader/grader-slurm.sh`. Follow the steps 1-4 from **Part 5:
Benchmarking Performance** and then run:

    sbatch grader-slurm.sh

For this assignment, there will be **no autograder** on Gradescope. We
will run the grader on the CS cluster and will manually enter in the
score into Gradescope. However, you **must still submit your final
commit to Gradescope**.

**There is maximum timeout limit of 10 minutes for each test. No credit
is given to that specific test if it exceeds that limit**. SLURM has a
maximum job time for 10 minutes; therefore, you may have to run them on
a test by test basis if your `go run proj2/grader proj2` takes in total
more than 10 minutes. However, you will still get full points as long as
each single test run is below 10 minutes, regardless of how long it
takes in total.

## Design, Style and Cleaning up

Before you submit your final solution, you should, remove

- any `Printf` statements that you added for debugging purposes and
- all in-line comments of the form: "YOUR CODE HERE" and "TODO ..."
- Think about your function decomposition. No code duplication. This
  homework assignment is relatively small so this shouldn't be a major
  problem but could be in certain problems.

Go does not have a strict style guide. However, use your best judgment
from prior programming experience about style. Did you use good variable
names? Do you have any lines that are too long, etc.

As you clean up, you should periodically save your file and run your
code through the tests to make sure that you have not broken it in the
process.

## Submission

Before submitting, make sure you've added, committed, and pushed all
your code to GitHub. You must submit your final work through Gradescope
(linked from our Canvas site) in the "Project \#2" assignment page via
two ways,

1. **Uploading from Github directly (recommended way)**: You can link
   your Github account to your Gradescope account and upload the
   correct repository based on the homework assignment. When you submit
   your homework, a pop window will appear. Click on "Github" and then
   "Connect to Github" to connect your Github account to Gradescope.
   Once you connect (you will only need to do this once), then you can
   select the repository you wish to upload and the branch (which
   should always be "main" or "master") for this course.
2. **Uploading via a Zip file**: You can also upload a zip file of the
   homework directory. Please make sure you upload the entire directory
   and keep the initial structure the **same** as the starter code;
   otherwise, you run the risk of not passing the automated tests.

As a reminder, for this assignment, there will be **no autograder** on
Gradescope. We will run the grader on the CS cluster and will manually
enter in the score into Gradescope. However, you **must still submit
your final commit to Gradescope**.
