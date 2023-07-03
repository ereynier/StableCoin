# Project Title

Decentralized Stablecoin

## Table of Contents

- [About The Project](#about-the-project)
  - [Built With](#built-with)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)
- [Acknowledgments](#acknowledgments)

## About The Project

This project is an algorithmic decentralized stablecoin based on the Patrick Collins course. It is implemented in Solidity using the Foundry framework. The project leverages OpenZeppelin contracts for security and incorporates Chainlink for reliable external data feeds.

### Built With

- [![Solidity](https://img.shields.io/badge/Solidity-363636?style=for-the-badge&logo=solidity&logoColor=white)](https://soliditylang.org/)
- [![Foundry](https://img.shields.io/badge/Foundry-008EFD?style=for-the-badge&logo=ethereum&logoColor=white)](https://foundry.finance/)
- [![OpenZeppelin](https://img.shields.io/badge/OpenZeppelin-2D3436?style=for-the-badge&logo=ethereum&logoColor=white)](https://openzeppelin.com/)
- [![Chainlink](https://img.shields.io/badge/Chainlink-375BD2?style=for-the-badge&logo=chainlink&logoColor=white)](https://chain.link/)

## Getting Started

To get started with the Decentralized Stablecoin project, follow the steps below.

### Prerequisites

- [Forge CLI](https://github.com/austintgriffith/cli) - Install the Forge CLI to build, test, and deploy the project.

### Installation

1. Clone the repo
   ```sh
   git clone https://github.com/your_username/repo_name.git
    ```
2. Set environment variables
    - Create a .env file in the project root directory.
    - Add the following environment variables to the .env file:
    ```env
    SEPOLIA_RPC_URL=<your_rpc_url>
    PRIVATE_KEY=<your_private_key>
    ETHERSCAN_API_KEY=<your_etherscan_api_key>
    ```

## Usage

This section describes how to use the Decentralized Stablecoin project.

### Deploying the Project

To deploy the project, run the following command:

```sh
make deploy [ARGS=...]
```

For example, to deploy the project on the "sepolia" network, run:

```sh
make deploy ARGS="--network sepolia"
```

<!-- CONTRIBUTING -->
## Contributing

Contributions are welcome and appreciated! If you would like to contribute to the Decentralized Stablecoin project, please follow these steps:

1. Fork the project repository.
2. Create a new branch for your feature (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a pull request to the main repository.

Your contributions will be reviewed and merged if they align with the project's goals.

## License

The Decentralized Stablecoin project is distributed under the MIT License. See `LICENSE.txt` for more information.

<!-- CONTACT -->
## Contact

If you have any questions or suggestions regarding the Decentralized Stablecoin project, feel free to reach out:

Estéban Reynier - [@EstebanReynier](https://twitter.com/EstebanReynier) - [ereynier.42@gmail.com](mailto:ereynier.42@gmail.com)

Project Link: [https://github.com/ereynier/StableCoin](https://github.com/ereynier/StableCoin)

<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

* [Patrick Collins Solidity course](https://www.youtube.com/playlist?list=PL4Rj_WH6yLgWe7TxankiqkrkVKXIwOP42)
* [Foundry doc](https://book.getfoundry.sh/)
* [Chainlink doc](https://docs.chain.link/)
* [OpenZeppelin doc](https://docs.openzeppelin.com/contracts/4.x/)
<p align="right">(<a href="#readme-top">back to top</a>)</p>
