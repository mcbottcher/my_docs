.. role:: yaml(code)
   :language: yaml

GitHub Actions
==============

GitHub Actions is an automation tool that allows developers to automate their workflows, build,
test, and deploy their code directly from their GitHub repository.

----

Components of GitHub Actions
----------------------------

A GitHub Actions *workflow* can be triggered when an *event* occurs in your repository. A workflow
contains one or more *jobs* which can be run sequentially or in parallel. Each job runs inside a
*runner* (VM or container), and has one or more *steps* that either runs a script or an *action*.

- Workflow:
    - Configurable automated process
    - Defined by *yaml* file
    - Triggered by event, manually or on defined schedule
    - Defined in ``.github/workflows``
- Events:
    - GitHub activity that triggers workflow e.g. pull request, push to branch, issue opening
- Jobs:
    - A set of steps that will be executed on the same runner
    - You can share data between steps in the same job
    - Jobs run in parallel, but can be configured to be dependent on each other
- Actions:
    - Custom application that does a frequently repeated task
    - You can write your own, or find them on GitHub Marketplace
- Runners:
    - Server that executes a job
    - This can be a GitHub provided VM or you can host your own runner

----

Workflow YAML file
------------------

- :yaml:`name:`: The name of the workflow that appears in the "Actions" tab in GitHub
- :yaml:`run-name:`: The name of the workflow run that will appear on GitHub

    This can be customised by incrementing a number or showing the username of the person that 
    triggered the action e.g. :yaml:`run-name: ${{ github.actor }} workflow run`
- :yaml:`on:`: Specifies the trigger(s) for the workflow
- :yaml:`jobs:`: Groups together jobs that run in the workflow
- :yaml:`runs-on:`: Specifies where the job will be run
- :yaml:`steps:`: Lists the steps for the job
- :yaml:`uses:`: Specifies the pre-defined action that a step will use
- :yaml:`run:`: Tells the job to execute a command on the runner
- :yaml:`needs:`: Used when a job needs to wait for another job to complete

Using Variables
^^^^^^^^^^^^^^^

You can add custom variables to your worflow YAML file. In the example the variables will be
available to the given script.

.. code-block:: yaml

    steps:
        - run: my_script.scr
          env:
            MY_VAR_1: 53
            MY_VAR_2: hello

Using Scripts and Shell Commands
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

You can either run just a single command, or a script from your local repo, provided with a shell type

.. code-block:: yaml

    steps:
        - run: npm install -g bats
        - name: Run script
          run: ./.github/scripts/build.sh
          shell: bash

Sharing Data Between Jobs
^^^^^^^^^^^^^^^^^^^^^^^^^

If you want to share files between jobs, or just save them for later reference,
you can save them as artifacts.

- Creating an artifact:

.. code-block:: yaml

    example-job:
        name: Save output
        steps:
        - shell: bash
          run: |
            expr 1 + 1 > output.log
        - name: Upload output file
          uses: actions/upload-artifact@v3
          with:
            name: output-log-file
            path: output.log
            if-no-files-found: error
            retention-days: 1

- Downloading an artifact

.. code-block:: yaml

    example-job:
        steps:
        - name: Download a single artifact
          uses: actions/download-artifact@v3
          with:
            name: output-log-file
            path: ${{ github.workspace }}/output-log-file

Workflow Triggers - Events
^^^^^^^^^^^^^^^^^^^^^^^^^^

- `pull_reqest`

    - You can specify a branch/branches with `branches:`
    
    - You can specify which particular file changes will trigger this with
      `paths:`. You can use expressions here like `"*,py"` to trigger on a
      change in a python file.

- `workflow_dispatch`: Allows you to run the workflow manually from GitHub actions tab

- `repository_dispatch`: Allows you to trigger a workflow using a webhook.

- `schedule`: Can set it to run at specified times, e.g. using the `cron` tag

.. code-block:: yaml
    :caption: Example Cron job

    on:
      schedule:
        - cron: "0 4 * * *" # run at 4am (UTC) every day

- `workflow_call`: Uses Github's reusable workflow model, workflow is called from another workflow.

----

Actions Files
-------------

The actions you use can be located in:
    - The same repo as the worflow file
    - Any public repo
    - A published Docker container image on Docker GitHub

See `GitHub Marketplace <https://github.com/marketplace?type=actions>`_ for some pre-defined actions.

Adding Actions
^^^^^^^^^^^^^^

- From Marketplace:
    - Copy the *uses* tag to your worflow e.g. :yaml:`uses: actions/upload-artifact@v3.1.2`
    - The action may require you to provide inputs
- From Same Repo:
    - You can either use ``{owner}/{repo}@{ref}`` or ``./path/to/dir`` syntax

.. code-block:: yaml

    - uses: ./.github/actions/hello-world-action

- From a Public Repo:
    - Use ``{owner}/{repo}@{ref}``
- A container from Docker Hub
    - Use ``docker://{image}:{tag}``

Action Release Management
^^^^^^^^^^^^^^^^^^^^^^^^^

You should indicate the version of the action you'd like to use based on your comfort with accepting
automatic updates.

.. note::
    It is recommended to use the SHA commit value when using third-party actions

- Using tags
    - :yaml:`uses: actions/javascript-action@v1.0.1`
- Using SHA
    - :yaml:`uses: actions/javascript-action@a824008085750b8e136effc585c3cd6082bd575f`
- Using branches
    - :yaml:`uses: actions/javascript-action@main`

Action Inputs and Outputs
^^^^^^^^^^^^^^^^^^^^^^^^^

To see the inputs and outputs of an action, check the ``action.yml`` in the root of the repo.

.. code-block:: yaml

    name: "Example"
    description: "Receives file and generates output"
    inputs:
    file-path: # id of input
        description: "Path to test script"
        required: true
        default: "test-file.js"
    outputs:
    results-file: # id of output
        description: "Path to results file"

----

Action File Fields
^^^^^^^^^^^^^^^^^^

See `Metadata Syntax for GitHub Actions <https://docs.github.com/en/actions/creating-actions/metadata-syntax-for-github-actions>`_.

.. TODO, add link to above section instead of just writing above section

- name
- author
- description
- inputs : see above section
- outputs : see above section 
- runs : Specifies how the action is executed
    - runs composite actions:

    .. code-block:: yaml

        runs:
          using: "composite"
          steps:
            - name: "Run Sphinx Build Script"
              run: $GITHUB_ACTION_PATH/script.sh
              shell: bash

    - runs Docker container:

    .. code-block:: yaml

        runs:
          using: 'docker'
          image: 'Dockerfile'

.. warning::
    Be careful when your Dockerfile is not in the root of your repo since it cannot access
    anything above it in the directory tree. If this is the case you will have to use script
    to run docker from the root pointing at the Dockerfile further down the directory tree

- branding: Create an icon that is shown on GitHub marketplace

----

Running Scripts
---------------

You can run scripts as part of your ``composite steps`` section of either a action file or workflow file.

.. code-block:: yaml

    using: "composite"
    steps:
      - name: "Run Sphinx Build Script"
        run: $GITHUB_ACTION_PATH/script.sh
        shell: bash

.. note::
    ``$GITHUB_ACTION_PATH`` specifies the path to the action file it is running from.

.. note::
    Even if the script is started from a random place in the repo, it seems that the working
    directory when the script starts is the root of the github repo.

If you want a script to run, you have to make sure it has it's permission set to executable.
This executable status is included when you commit the file to GitHub.

.. code-block:: bash
    
    sudo chmod +x <your_script.sh>

.. warning::
    A script might still exit with a sucessfull exit code even if one of the commands returned an
    error code. This could make your workflow seem like it succeeded. You can use the ``set -e`` in
    your script file to cause the script to exit with error on the first command that returns an error

----

Expressions
-----------

Expressions are used to programmatically set environment variables.

You use special syntax to evaluate as an expression: ``${{ <expression> }}``.

If you use the expression within an ``if`` conditional, you can ommit the expression syntax above.

Examples
^^^^^^^^

.. code-block:: yaml

    steps:
      - uses: actions/hello-world-javascript-action@e76147da8e5c81eaf017dede5645551d4b94427b
        if: ${{ <expression> }}

.. code-block:: yaml

    env:
      MY_ENV_VAR: ${{ <expression> }}

Literals
^^^^^^^^

You can use: boolean, null, number or string data types

.. code-block:: yaml

    env:
      myNull: ${{ null }}
      myBoolean: ${{ false }}
      myIntegerNumber: ${{ 711 }}
      myFloatNumber: ${{ -9.2 }}
      myHexNumber: ${{ 0xff }}
      myExponentialNumber: ${{ -2.99e-2 }}
      myString: Mona the Octocat
      myStringInBraces: ${{ 'It''s open source!' }} # note the '', which is required to output It's

Operators
^^^^^^^^^

- Logical operators: ``|| && ! != == <= < > >=``
- Index: ``[]``
- Logical grouping: ``()``
- Property dereference: ``.``

GitHub uses loose equality comparisons: If types don't match, variable is cast to a number.

- NULL -> ``0``
- Boolean
    - true -> ``1``
    - false -> ``0``
- String
    - Empty string -> ``0``
    - Parsed from any legal JSON format, otherwise ``NaN``
- Array -> ``NaN``
- Object -> ``NaN``

.. warning::
    A comparison of one ``NaN`` to another ``NaN`` doesn't result in a ``true``

.. note::
    GitHub ignores case when comparing strings

.. note::
    Objects and array are only considered equal when they are the same instance


Functions
^^^^^^^^^

GitHub provides some builtin functions. Some functions cast input to a string:

- NULL -> ``''``
- Boolean -> ``'true'`` or ``'false'``
- Number -> decimal format
- Array/Object: Not converted to a string

Functions:

- ``contains( search, item)``: does the string contain the given slice
- ``startsWith( search, item)``: does the string start with the given slice
- ``endsWith( search, item)``: does the string end with given slice
- ``format( string, replaceValue0...)``: Formats a string, variables inserted in ``{N}```, where N is an integer
- ``join( array, opetionalSeperator)``: concatenates elements into a string
- ``toJSON( value)``: prints JSON representation of a value
- ``fromJSON(value)``: returns JSON data type for value
- ``hashFiles(path)``: returns the hash for one or multiple files given by path
- ``success()``: checks none of the previous steps have been cancelled or failed
- ``always()``: always executes, even if step is cancelled
- ``cancelled()``: true if workflow is cancelled
- ``failure()``: returns ``true`` if any previous step or ancestor job fails

----

Contexts
--------

Contexts are a way to access information about workflow runs, variables, runner environments, jobs, and steps.
Each context is an object that contains properties, which can be strings or other objects.

Examples of some context types include: ``github, env, vars, job, steps, runner, secrets, needs``...

As part of an expression you can access context info in two ways:

    - ``github['sha']``
    - ``github.sha``

.. note::
    Attempting to dereference a non-existent property evaluates to an empty string

You can print a context to the log if you want to see what is inside of them:

.. code-block:: yaml

    run: echo '${{ toJSON(github) }}'
    run: echo '${{ toJSON(steps) }}'

Contexts have many attributes so it is best to look `here <https://docs.github.com/en/actions/learn-github-actions/contexts>`_ for documentation.

----

Variables
---------

Variables provide a way to reuse non-sensitive configuration information.

You can set environment variables on a workflow level, in the workflow YAML file, or across multiple workflows at the organisation,
repository or environment level.

Single Workflow Variables
^^^^^^^^^^^^^^^^^^^^^^^^^

You can set workflow variables at three levels:

1. Workflow level
2. Job level
3. Step level

.. note::
    You can list all variables available at a particular step by using ``run: env``

Configuration Variables across multiple workflows
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. warning::
    These are still in beta and subject to change

Configuration variables can be set at organisation, repository or environment level. Configuration variables are available in the ``vars`` context

If variables have the same name, the one with the lowest level takes precedence: organisation < repository < environment.

You can add configuration variables in the GitHub settings. This is same for secrets.

----

Example Commenting on PR
------------------------

.. code-block:: yaml
    :caption: Adding PR to your workflow Events

    on:
    pull_request:
        types: [opened, synchronize, reopened]

In the example, we see that this pull_request event is triggered when the PR is opened
and re-opened. Synchronize triggers the event when the PR is updated with a push.

.. code-block:: yaml
    :caption: Example step

    - name: Update PR
      if: ${{ github.event_name == 'pull_request' }}
      uses: actions/github-script@v6
      with:
        script: |
          github.rest.issues.createComment({
          issue_number: context.issue.number,
          owner: context.repo.owner,
          repo: context.repo.repo,
          body: '👋 Check the Sphinx build passed before merge!'
          })

The step in the example uses the GitHub provided ``github-script`` action which is used for issues and PRs.
In GitHub, a PR is treated the same as an issue.

The step will only run if the triggering event is of type ``pull_request``, which is extracted from the github
context.

.. note::
    The nice thing about this event type is that it will actually block the PR from being merged until
    the workflow has completed successfully. This is done automatically.

GitHub Actions Security
-----------------------

Check out this link: https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions

----

Triggering Actions in another Repo
----------------------------------

You can use action files from another repo in your workflow.

If you are using your own action, it is recommended to have a separate repository for your
action.
However it is also possible to have your action within your repo with other things in it.

For example, an action file in ``actions/my_action/action.yml``

To call an action from another repo, you have to alter your repo settings to allow calls from
other repositories to access actions.

.. code-block::
    :caption: Example workflow calling action in another repo

    runs-on: ubuntu-latest
    steps:
      - name: "Test-action"
        uses: <repository_owner>/<repository_name>/actions/my_action@<branch_name or reference>

.. code-block::
    :caption: Example action.yml

    using: "composite"
    steps:
        - run: |
            python ${{ github.action_path }}/../my_script.py
          shell: bash

.. note::
    As seen in the example, you need to use the ``github.action_path`` to reference files
    in relation to the actions file. 

Doing it this way even allows you to call actions in the same repository you are in.
The other method you can use, is to first checkout the repository containing the action
you want to run, and then call the action locally:

.. code-block:: yaml
    :caption: Example calling action locally

    - uses: actions/checkout@v4 # need to checkout repo first in this case
    - uses: ./.github/<action_name>

In this case the action version is determined by the reference you use to checkout the 
repository containing the action.

.. note:: 
    In theory you can have an action.yml anywhere in your repo, not just in the .github/actions.
    It makes more sense as a public action repo to have the action in the repo root.

----

Calling Reusable Workflow
-------------------------

You can call a workflow both in the same repo or in another repo.

.. code-block:: yaml
    :caption: Example calling reusable workflow

    uses: <org>/<repo_name>/.github/workflows/my_workflow.yml@main
    # OR
    uses: ./.github/workflows/my_workflow.yml

----

Job flow control
----------------

Here is an example of some job control flow. You can use the ``needs`` keyword to 
achieve this.

.. code-block:: yaml
    :caption: Example of job flow control

    jobs:
        job1:
            ...
        
        job2:
            needs: job1
            # note not in ${{ }}
            if: |
                always() &&
                ( needs.job1.result != 'skipped' )

The use of ``always`` means that this job will still be evaluated even if the previous
dependent job is failed or cancelled or skipped.

----

Workflow inputs
---------------

Undefined workflow inputs are treated as empty strings.

.. code-block:: yaml
    :caption: Example with undefined workflow input

    on:
        workflow_dispatch:
        
        workflow_call:
            my_input:
                description: ''
                required: true
                type: boolean

    # Later on if you call inputs.my_input, if called from workflow_call it will be the input boolean,
    # if from workflow_dispatch (i.e. undefined), it will be an empty string ''

----

If-Else
-------

Github actions has a shorthand for doing ``if else`` type statements.

.. code-block:: yaml
    :caption: Example if else

    ${{ inputs.use_local_image == 'true' && '--use_local_image' || '' }} \
    ${{ inputs.image_tag && format('--image_tag="{0}"', inputs.image_tag) || '' }} \

If the expression is evaluated to True, then the statement after the ``&&`` will be used.
If the expression is evaluated to False, then the statement after the ``||`` will be used.

----

Setting Github Actions step output
----------------------------------

To do this you simply write to the ``GITHUB_OUTPUT`` environment file.
To access the output from a step, you need to assign the step an ``id``.

.. code-block:: yaml
    :caption: Example setting Github Actions Step output

    outputs:
        number-of-days:
            description: "Number of days since unix epoch - UTC"
            value: ${{ steps.get-days.outputs.days }}
    
    runs:
        using: "composite"
        steps:
            - id: get-days
              # -u gives UTC, +%s gives value in seconds, / 86400 converts seconds to days
              run: echo "days=$(( $(date -u +%s) / 86400 ))" >> $GITHUB_OUTPUT
              shell: bash

----

Writing to Github Actions Output from python
--------------------------------------------

Wrtiting to the Github Output like this will be the variable will be available
in the step.output for the action step calling the python script.

.. code-block:: python
    :caption: Example writing to github actions output

    with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as var:
        var.write(f"run_job_config={json.dumps(run_job_config)}\n")

.. note:: 
    ``json.dumps`` from a dictionary is a good way to get data in a nice format for using in Github Actions.

----

Debugging in Github Actions
---------------------------

Sometimes it is nice to view a context in github actions for debugging. It is not possible to
simply echo. This method can be used for any json based github actions data.

.. code-block:: yaml
    :caption: Example debugging in Github Actions

    - name: "Debug Job Output"
      run: |
        echo "OUTPUTS:"
        python -c 'import json; json_string=${{ toJson(steps.process-request.outputs.temporary_labels) }}; \
          print(f"temporary_labels = {json.dumps(json.loads(json_string), indent=2)}")'

----

Evaluation of inputs
--------------------

Actions inputs are always strings!

If an input has a default of ``""`` , then you can do something like what follows in an **Action…**

.. code-block:: yaml

    run: |
        python my_script.py ${{ inputs.marks && format('--marks="{0}"', inputs.marks) || '' }} \

In a workflow, if you have an input as a boolean type, you can do the following in a step ``if``

.. code-block:: yaml

    - if: inputs.use_test_image
    # if using a ! you should use ${{ }} since ! is something in yaml syntax

you can also do this in a workflow step:

.. code-block:: yaml

    run: |
        python my_script.py ${{ inputs.use_test_image && '--image_name=test_image' || '' }} \

----

Matrix Jobs:
------------

Matrix jobs allow you to run a dynamic number of jobs in parallel.

.. code-block:: yaml
    :caption: Example setting up a matrix job

    test-session:
        needs: [setup-test-session, set-temp-labels]
        if: |
            always() &&
            ((needs.setup-test-session.result == 'success')  &&
            ((needs.set-temp-labels.result == 'success') ||
            (needs.set-temp-labels.result == 'skipped')))
        strategy:
            fail-fast: false
            matrix:
                test-run: ${{ fromJson(needs.setup-test-session.outputs.run_job_config) }}
        runs-on: [self-hosted, "${{ matrix.test-run.runner_label }}"]


----

Format for Json inputs
----------------------

.. code-block:: yaml

    with:
      labels: '{"<runner_name>": ["<label1>"]}'

This is how you can do json as an input. Note the use of ' and “.
This is because you should pass json as a string within github actions, and use
the ``toJson`` and ``fromJson`` to do the conversions between strings and json.

From the Github UI, use: ``{"<runner_name>": ["<label1>"]}`` without external ' or “

----

Sources
-------

- https://docs.github.com/en/actions/learn-github-actions
