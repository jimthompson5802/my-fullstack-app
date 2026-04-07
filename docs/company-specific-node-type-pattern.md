## Valid Architecture

`Node C` is valid custom node-type: `external-proxy`

```json
{
    "$schema": "https://calm.finos.org/release/1.2/meta/calm.json",
    "unique-id": "three-node-system",
    "name": "Three Node System",
    "description": "Sample architecture with three nodes connected in sequence: node-a connects to node-b, node-b connects to node-c",
    "nodes": [
        {
            "unique-id": "node-a",
            "node-type": "service",
            "name": "Node A",
            "description": "First service in the chain"
        },
        {
            "unique-id": "node-b",
            "node-type": "service",
            "name": "Node B",
            "description": "Middle service in the chain"
        },
        {
            "unique-id": "node-c",
            "node-type": "external-proxy",
            "name": "Node C",
            "description": "Final service in the chain"
        }
    ],
    "relationships": [
        {
            "unique-id": "node-a-to-node-b",
            "description": "Sends requests to",
            "relationship-type": {
                "connects": {
                    "source": {
                        "node": "node-a"
                    },
                    "destination": {
                        "node": "node-b"
                    }
                }
            }
        },
        {
            "unique-id": "node-b-to-node-c",
            "description": "Sends requests to",
            "relationship-type": {
                "connects": {
                    "source": {
                        "node": "node-b"
                    },
                    "destination": {
                        "node": "node-c"
                    }
                }
            }
        }
    ]
}

```

```bash
$ calm validate -a docs/calm/three-node-system.architecture.json -p docs/calm/patterns/company-specific.pattern.json -u docs/calm/url-mapping.json -f pretty
(node:21954) [DEP0040] DeprecationWarning: The `punycode` module is deprecated. Please use a userland alternative instead.
(Use `node --trace-deprecation ...` to show where the warning was created)
info [file-system-document-loader]:     docs/calm/three-node-system.architecture.json exists, loading as file...
info [file-system-document-loader]:     docs/calm/patterns/company-specific.pattern.json exists, loading as file...
info [calm-validate]:     Formatting output as pretty
Summary
- Errors: no (0)
- Warnings: no (0)
- Info/Hints: 0

No issues found.
```

## Invalid Architecture

`Node C` is invalid custom node-type: `unknown-type`

```json
{
    "$schema": "https://calm.finos.org/release/1.2/meta/calm.json",
    "unique-id": "three-node-system",
    "name": "Three Node System",
    "description": "Sample architecture with three nodes connected in sequence: node-a connects to node-b, node-b connects to node-c",
    "nodes": [
        {
            "unique-id": "node-a",
            "node-type": "service",
            "name": "Node A",
            "description": "First service in the chain"
        },
        {
            "unique-id": "node-b",
            "node-type": "service",
            "name": "Node B",
            "description": "Middle service in the chain"
        },
        {
            "unique-id": "node-c",
            "node-type": "unknown-type",
            "name": "Node C",
            "description": "Final service in the chain"
        }
    ],
    "relationships": [
        {
            "unique-id": "node-a-to-node-b",
            "description": "Sends requests to",
            "relationship-type": {
                "connects": {
                    "source": {
                        "node": "node-a"
                    },
                    "destination": {
                        "node": "node-b"
                    }
                }
            }
        },
        {
            "unique-id": "node-b-to-node-c",
            "description": "Sends requests to",
            "relationship-type": {
                "connects": {
                    "source": {
                        "node": "node-b"
                    },
                    "destination": {
                        "node": "node-c"
                    }
                }
            }
        }
    ]
}

```


```bash
$ calm validate -a docs/calm/three-node-system.architecture.json -p docs/calm/patterns/company-specific.pattern.json -u docs/calm/url-mapping.json -f pretty
(node:22894) [DEP0040] DeprecationWarning: The `punycode` module is deprecated. Please use a userland alternative instead.
(Use `node --trace-deprecation ...` to show where the warning was created)
info [file-system-document-loader]:     docs/calm/three-node-system.architecture.json exists, loading as file...
info [file-system-document-loader]:     docs/calm/patterns/company-specific.pattern.json exists, loading as file...
info [calm-validate]:     Formatting output as pretty
Summary
- Errors: yes (1)
- Warnings: no (0)
- Info/Hints: 0

ERROR issues:
- In three-node-system.architecture.json (/Users/jim/Desktop/calm-demos/my-fullstack-app/docs/calm/three-node-system.architecture.json):
  ERROR json-schema: must be equal to one of the allowed values (expected one of ["actor","ecosystem","system","service","database","network","ldap","webclient","data-asset","external-proxy"])
    path: /nodes/node-c/node-type
    at line 21, col 26 (/Users/jim/Desktop/calm-demos/my-fullstack-app/docs/calm/three-node-system.architecture.json)
    schema: #/allOf/1/properties/node-type/enum
    21 |             "node-type": "unknown-type",
       |                          ^^^^^^^^^^^^^^
```


## Custom node type standard: `custom-node-types.standard.json`

```json
{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "https://my-fullstack-app.example.com/standards/custom-node-types.json",
    "title": "Custom Node-Type Standard",
    "description": "Restricts node-type to an approved set of standard CALM types plus organisation-specific custom types. All standard CALM node-types are preserved; additional custom types are added via the same enum.",
    "allOf": [
        {
            "$ref": "https://calm.finos.org/release/1.2/meta/core.json#/defs/node"
        },
        {
            "type": "object",
            "properties": {
                "node-type": {
                    "description": "The approved node-type for this architecture. Combines all core CALM types with organisation-specific custom types.",
                    "enum": [
                        "actor",
                        "ecosystem",
                        "system",
                        "service",
                        "database",
                        "network",
                        "ldap",
                        "webclient",
                        "data-asset",
                        "external-proxy"
                    ]
                }
            },
            "required": ["node-type"]
        }
    ]
}
```

## Pattern to enforce the custom node-types: `company-specific.pattern.json`

```json
{
    "$schema": "https://calm.finos.org/release/1.2/meta/calm.json",
    "$id": "https://my-fullstack-app.example.com/patterns/custom-typed-system.pattern.json",
    "title": "Custom Node-Type Enforced Pattern",
    "description": "Pattern that restricts all nodes to approved standard and custom node-types",
    "type": "object",
    "properties": {
        "nodes": {
            "type": "array",
            "minItems": 1,
            "items": {
                "$ref": "https://my-fullstack-app.example.com/standards/custom-node-types.json"
            }
        },
        "relationships": {
            "type": "array",
            "minItems": 1
        }
    },
    "required": ["nodes", "relationships"]
}
```