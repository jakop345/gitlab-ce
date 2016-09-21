# Introduction to pipelines and builds

>**Note:**
Introduced in GitLab 8.8.

## Pipelines

A pipeline is a group of [builds] that get executed in [stages] \(batches). All
of the builds in a stage are executed in parallel (if there are enough
concurrent [runners]), and if they all succeed, the pipeline moves on to the
next stage. If one of the builds fails, the next stage is not (usually)
executed.

## Builds

Builds are individual runs of [jobs]. Not to be confused with a `build` job or
`build` stage.

## Defining pipelines

Pipelines are defined in `.gitlab-ci.yml` by specifying [jobs] that run in
[stages].

See full [documentation](yaml/README.md#jobs).

## Seeing pipeline status

You can find the current and historical pipeline runs under **Pipelines** for your
project.

## Seeing build status

Clicking on a pipeline will show the builds that were run for that pipeline.

## How pipeline duration is calculated?

Total running time for a given pipeline would exclude retries and pending
(queue) time. We could reduce this problem down to finding the union of
periods.

So each job would be represented as a `Period`, which consists of
`Period#first` as when the job started and `Period#last` as when the
job was finished. A simple example here would be:

* A (1, 3)
* B (2, 4)
* C (6, 7)

Here A begins from 1, and ends to 3. B begins from 2, and ends to 4.
C begins from 6, and ends to 7. Visually it could be viewed as:

    0  1  2  3  4  5  6  7
       AAAAAAA
          BBBBBBB
                      CCCC

The union of A, B, and C would be (1, 4) and (6, 7), therefore the
total running time should be:

    (4 - 1) + (7 - 6) => 4

## Badges

There are build status and test coverage report badges available.

Go to pipeline settings to see available badges and code you can use to embed
badges in the `README.md` or your website.

### Build status badge

You can access a build status badge image using following link:

```
http://example.gitlab.com/namespace/project/badges/branch/build.svg
```

### Test coverage report badge

GitLab makes it possible to define the regular expression for coverage report,
that each build log will be matched against. This means that each build in the
pipeline can have the test coverage percentage value defined.

You can access test coverage badge using following link:

```
http://example.gitlab.com/namespace/project/badges/branch/coverage.svg
```

If you would like to get the coverage report from the specific job, you can add
a `job=coverage_job_name` parameter to the URL. For example, it is possible to
use following Markdown code to embed the est coverage report into `README.md`:

```markdown
![coverage](http://gitlab.com/gitlab-org/gitlab-ce/badges/master/coverage.svg?job=coverage)
```

The latest successful pipeline will be used to read the test coverage value.

[builds]: #builds
[jobs]: yaml/README.md#jobs
[stages]: yaml/README.md#stages
[runners]: runners/README.md
