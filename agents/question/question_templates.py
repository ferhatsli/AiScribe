QUESTION_TEMPLATES = {
    "character": {
        "appearance": {
            "question": "What should the character's appearance be like?",
            "options": ["young", "elderly", "tall", "petite"],
            "examples": "For example: 'A tall, slender figure with flowing silver hair'",
            "follow_up": {
                "facial_expression": {
                    "question": "What facial expression should the character have?",
                    "options": ["cheerful", "determined", "mysterious", "worried"],
                    "examples": "For example: 'A gentle smile with knowing eyes'"
                },
                "clothing": {
                    "question": "What should the character be wearing?",
                    "options": ["casual", "formal", "fantasy", "period-specific"],
                    "examples": "For example: 'A flowing red cloak with golden trim'"
                }
            }
        }
    },
    "setting": {
        "environment": {
            "question": "What kind of environment should be depicted?",
            "options": ["natural", "urban", "fantasy", "historical"],
            "examples": "For example: 'A misty forest at dawn'",
            "follow_up": {
                "weather": {
                    "question": "What should the weather conditions be?",
                    "options": ["clear", "rainy", "stormy", "misty"],
                    "examples": "For example: 'Light fog with rays of sunlight breaking through'"
                },
                "time": {
                    "question": "What time of day/season should it be?",
                    "options": ["dawn", "noon", "dusk", "night"],
                    "examples": "For example: 'Early morning in autumn'"
                }
            }
        }
    },
    "atmosphere": {
        "mood": {
            "question": "What mood should the scene convey?",
            "options": ["peaceful", "mysterious", "dramatic", "whimsical"],
            "examples": "For example: 'A serene and mystical atmosphere'",
            "follow_up": {
                "lighting": {
                    "question": "How should the lighting enhance the mood?",
                    "options": ["soft", "dramatic", "ethereal", "dark"],
                    "examples": "For example: 'Soft, golden light filtering through trees'"
                }
            }
        }
    },
    "action": {
        "movement": {
            "question": "What kind of movement or action should be shown?",
            "options": ["walking", "running", "floating", "dancing"],
            "examples": "For example: 'Gracefully dancing in the wind'",
            "follow_up": {
                "intensity": {
                    "question": "What should be the intensity of the action?",
                    "options": ["gentle", "dynamic", "frozen", "flowing"],
                    "examples": "For example: 'A gentle, flowing movement'"
                }
            }
        }
    }
} 