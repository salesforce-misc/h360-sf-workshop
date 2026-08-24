import { useAsyncData } from '@/hooks/useAsyncData';
import { executeGraphQL } from '@/api/graphqlClient';
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Spinner } from '@/components/ui/spinner';

const ORDERS_QUERY = /* GraphQL */ `
  query Orders {
    uiapi {
      query {
        Order__c(first: 10) {
          edges {
            node {
              Id
              Order_Number__c {
                value
              }
              Status__c {
                value
              }
              Status_Summary__c {
                value
              }
              Next_Action__c {
                value
              }
              Owner_Name__c {
                value
              }
            }
          }
        }
      }
    }
  }
`;

type OrdersResult = {
  uiapi: {
    query: {
      Order__c: {
        edges: {
          node: {
            Id: string;
            Order_Number__c: { value: string | null };
            Status__c: { value: string | null };
            Status_Summary__c: { value: string | null };
            Next_Action__c: { value: string | null };
            Owner_Name__c: { value: string | null };
          };
        }[];
      };
    };
  };
};

export default function OrderStatus() {
  const { data, loading, error } = useAsyncData<OrdersResult>(
    () => executeGraphQL<OrdersResult, Record<string, never>>(ORDERS_QUERY),
    []
  );

  if (loading) {
    return (
      <div className="flex items-center justify-center p-8">
        <Spinner />
      </div>
    );
  }

  if (error) {
    return (
      <Card>
        <CardContent className="p-6">
          <p className="text-red-600">Error loading orders: {error}</p>
        </CardContent>
      </Card>
    );
  }

  const rows = data?.uiapi.query.Order__c.edges ?? [];

  return (
    <Card>
      <CardHeader>
        <CardTitle>Order Status</CardTitle>
      </CardHeader>
      <CardContent>
        {rows.length === 0 ? (
          <p className="text-muted-foreground">No orders found.</p>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Order Number</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Status Summary</TableHead>
                <TableHead>Next Action</TableHead>
                <TableHead>Owner</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map(({ node }) => (
                <TableRow key={node.Id}>
                  <TableCell>{node.Order_Number__c.value}</TableCell>
                  <TableCell>{node.Status__c.value}</TableCell>
                  <TableCell>{node.Status_Summary__c.value}</TableCell>
                  <TableCell>{node.Next_Action__c.value}</TableCell>
                  <TableCell>{node.Owner_Name__c.value}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </CardContent>
    </Card>
  );
}
