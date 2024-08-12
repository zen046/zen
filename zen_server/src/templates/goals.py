from constants.constants import mental_health_prompt_template

GET_GOAL_RECOMMENDATION =  mental_health_prompt_template + """

you need to formulate a pre goal recommendation to help the mental state of the patient :-
The latest questionnaire answered by patient is given below use that and give some best goals that help the patient change the current mood and mental state.

The below is the example json you need to provide as response, Give atleast 5 goals,

{
title 
Short Description

long description
benefits:["benefit1","benefit2","benefit3"]
}

Give the response in array of objects.
Think like a professional therapist and give the response

Here is the response from patient

"""

GET_GOAL_TARGETS = mental_health_prompt_template + """

Given a patient goal you need to device a 7 days plan to help significantly reduce the patient issue
Here is the patient goal : "anger Management"

The above is the goal request from the patient.
You need to give JSON object in the following format
Example JSON :-
{
    1 : {
        "id": 1
        "objective": "Meditate",
        "description": "",
        "tasks": {
            1: {
                "id": 1
                "task": "Task 1",
                "status": "",
                "reflection": "", // this is user opinion of the task
                "status": "TO_DO"
            }
        },
    },
    2 : {
        "id": 2,
        "objective": "Meditate",
        "description": "",
        "tasks": {
            1: {
                "id": 1
                "task": "Task 1",
                "status": "",
                "reflection": "", // this is user opinion of the task
                "status": "TO_DO"
            }
        },
    }
}

GIVE 7 DAYS GOAL TARGETS AND INCLUDE TO_DO TO EVERY STATUS
Important Note :- Make sure to send proper JSON with proper Escape character, incase " is in the json
"""