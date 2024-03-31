import scaffoldConfig from "~~/scaffold.config";
import deployedContractsData from "~~/contracts/deployedContracts";
// import externalContractsData from "~~/contracts/externalContracts";
import type {
  ExtractAbiFunction,
  FunctionArgs,
  Abi,
  ExtractAbiInterfaces,
  ExtractArgs,
} from "abi-wan-kanabi/dist/kanabi";
import {
  UseContractReadProps,
  UseContractWriteProps,
} from "@starknet-react/core";

type ConfiguredChainId =
  (typeof scaffoldConfig)["targetNetworks"][0]["network"];
export type InheritedFunctions = { readonly [key: string]: string };

type Contracts = ContractsDeclaration[ConfiguredChainId];
export type ContractName = keyof Contracts;
export type Contract<TContractName extends ContractName> =
  Contracts[TContractName];
type AddExternalFlag<T> = {
  [ChainId in keyof T]: {
    [ContractName in keyof T[ChainId]]: T[ChainId][ContractName] & {
      external?: true;
    };
  };
};
export enum ContractCodeStatus {
  "LOADING",
  "DEPLOYED",
  "NOT_FOUND",
}

export type GenericContract = {
  address: string;
  abi: Abi;
};
export type GenericContractsDeclaration = {
  [network: string]: {
    [contractName: string]: GenericContract;
  };
};

// const deepMergeContracts = <
//   L extends Record<PropertyKey, any>,
//   E extends Record<PropertyKey, any>
// >(
//   local: L,
//   external: E
// ) => {
//   const result: Record<PropertyKey, any> = {};
//   const allKeys = Array.from(
//     new Set([...Object.keys(external), ...Object.keys(local)])
//   );
//   for (const key of allKeys) {
//     if (!external[key]) {
//       result[key] = local[key];
//       continue;
//     }
//     const amendedExternal = Object.fromEntries(
//       Object.entries(
//         external[key] as Record<string, Record<string, unknown>>
//       ).map(([contractName, declaration]) => [
//         contractName,
//         { ...declaration, external: true },
//       ])
//     );
//     result[key] = { ...local[key], ...amendedExternal };
//   }
//   return result as MergeDeepRecord<
//     AddExternalFlag<L>,
//     AddExternalFlag<E>,
//     { arrayMergeMode: "replace" }
//   >;
// };

const contractsData = deployedContractsData;

type IsContractDeclarationMissing<TYes, TNo> = typeof contractsData extends {
  [key in ConfiguredChainId]: any;
}
  ? TNo
  : TYes;

type ContractsDeclaration = IsContractDeclarationMissing<
  GenericContractsDeclaration,
  typeof contractsData
>;

type AbiStateMutability = "view" | "external";

export const contracts = contractsData as GenericContractsDeclaration | null;

export type UseScaffoldWriteConfig<
  TContractName extends ContractName,
  TFunctionName extends ExtractAbiFunctionNamesScaffold<
    ContractAbi<TContractName>,
    "external"
  >
> = {
  contractName: TContractName;
  // onBlockConfirmation?: (txnReceipt: TransactionReceipt) => void; TODO check this lines
  // blockConfirmations?: number;
} & IsContractDeclarationMissing<
  Partial<UseContractWriteProps>,
  {
    functionName: TFunctionName;
  } & Omit<
    UseContractWriteProps,
    "chainId" | "abi" | "address" | "functionName" | "mode"
  > &
    UseScaffoldArgsParam<TContractName, TFunctionName>
>;
// export type UseScaffoldWriteConfig = {
//   calls: Array<{
//     contractName: ContractName;
//     functionName: ExtractAbiFunctionNamesScaffold<
//       ContractAbi<ContractName>,
//       "external"
//     >;
//     args: any[]; // You can further refine this type based on your contract ABI
//   }>;
// };

type InferContractAbi<TContract> = TContract extends { abi: infer TAbi }
  ? TAbi
  : never;

export type ContractAbi<TContractName extends ContractName = ContractName> =
  InferContractAbi<Contract<TContractName>>;

export type FunctionNamesWithInputs<TContractName extends ContractName> =
  Exclude<
    Extract<
      Extract<
        ContractAbi<TContractName>[number],
        { type: "interface" }
      >["items"][number],
      {
        type: "function";
      }
    >,
    {
      inputs: readonly [];
    }
  >["name"];

type OptionalTupple<T> = T extends readonly [infer H, ...infer R]
  ? readonly [H | undefined, ...OptionalTupple<R>]
  : T;
type UnionToIntersection<U> = Expand<
  (U extends any ? (k: U) => void : never) extends (k: infer I) => void
    ? I
    : never
>;
type Expand<T> = T extends object
  ? T extends infer O
    ? { [K in keyof O]: O[K] }
    : never
  : T;

// helper function will only take from interfaces : //TODO: see if we can make it more generic
export type ExtractAbiFunctionNamesScaffold<
  TAbi extends Abi,
  TAbiStateMutibility extends AbiStateMutability = AbiStateMutability
> = ExtractAbiFunctionsScaffold<TAbi, TAbiStateMutibility>["name"];

// helper function will only take from interfaces : //TODO: see if we can make it more generic
export type ExtractAbiFunctionsScaffold<
  TAbi extends Abi,
  TAbiStateMutibility extends AbiStateMutability = AbiStateMutability
> = Extract<
  ExtractAbiInterfaces<TAbi>["items"][number],
  {
    type: "function";
    state_mutability: TAbiStateMutibility;
  }
>;

export type ExtractAbiFunctionScaffold<
  TAbi extends Abi,
  TFunctionName extends ExtractAbiFunctionNamesScaffold<TAbi>
> = Extract<
  ExtractAbiFunctionsScaffold<TAbi>,
  {
    name: TFunctionName;
  }
>;

type UseScaffoldArgsParam<
  TContractName extends ContractName,
  TFunctionName extends ExtractAbiFunctionNamesScaffold<
    ContractAbi<TContractName>
  >
> = TFunctionName extends ExtractAbiFunctionsScaffold<
  ContractAbi<TContractName>
>
  ? {
      args: OptionalTupple<
        UnionToIntersection<
          ExtractArgs<ContractAbi<TContractName>, TFunctionName>
        >
      >;
    }
  : {
      args?: never;
    };

export type UseScaffoldReadConfig<
  TContractName extends ContractName,
  TFunctionName extends ExtractAbiFunctionNamesScaffold<
    ContractAbi<TContractName>
  >
> = {
  contractName: TContractName;
} & IsContractDeclarationMissing<
  Partial<UseContractReadProps>,
  {
    functionName: TFunctionName;
  } & UseScaffoldArgsParam<TContractName, TFunctionName> &
    Omit<UseContractReadProps, "chainId" | "abi" | "address" | "functionName">
>;

export type AbiFunctionOutputs<
  TAbi extends Abi,
  TFunctionName extends string
> = ExtractAbiFunctionScaffold<TAbi, TFunctionName>["outputs"];
