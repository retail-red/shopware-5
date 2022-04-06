<?php

namespace SgateClickAndReserve\Subscriber;

use Enlight\Event\SubscriberInterface;
use Shopware\Components\CacheManager;
use Shopware\Components\Logger;
use Shopware\Components\HttpClient\HttpClientInterface;
use Shopware\Components\HttpClient\RequestException;
use Symfony\Component\HttpFoundation\Response;

class ConfigSubscriber implements SubscriberInterface
{
    /**
     * @var CacheManager
     */
    private $cacheManager;

    /**
     * @var HttpClientInterface
     */
    private $client;

    /**
     * @var Logger
     */
    private $logger;

    /**
     * @var string
     */
    private $pluginName;

    /**
     * ConfigSubscriber constructor.
     */
    public function __construct(Logger $logger, CacheManager $cacheManager, HttpClientInterface $client, $pluginName)
    {
        $this->cacheManager = $cacheManager;
        $this->client = $client;
        $this->logger = $logger;
        $this->pluginName = $pluginName;
    }

    public static function getSubscribedEvents(): array
    {
        return [
            'Enlight_Controller_Action_PostDispatchSecure_Backend_Config' => 'onPostDispatchConfig',
            'Enlight_Controller_Action_PreDispatchSecure_Backend_Config' => 'onPreDispatchConfig'
        ];
    }

    public function onPostDispatchConfig(\Enlight_Event_EventArgs $args): void
    {
        /** @var Shopware_Controllers_Backend_Config $subject */
        $subject = $args->get('subject');
        $request = $subject->Request();

        // If this is a POST-Request, and affects our plugin, we may clear the config cache
        if($request->isPost() && $request->getParam('name') === $this->pluginName) {
            $this->cacheManager->clearByTag(CacheManager::CACHE_TAG_CONFIG);
        }
    }

    private const API_URLS = [
        'development' => 'https://storefront-api.shopgatedev.io',
        'staging' => 'https://storefront-api.shopgatepg.io',
        'production' => 'https://storefront-api.shopgate.io'
    ];

    public function onPreDispatchConfig(\Enlight_Event_EventArgs $args): void
    {
        $request = $args->get('subject')->Request();
        if ($request->isPost() && $request->getParam('name') === $this->pluginName) {
            try {
                $response = $this->client->get(self::API_URLS[$request->getParam('apiStage')] . "/v1/locations?apiKey=" . $request->getParam('apiKey'));

                if ((int) $response->getStatusCode() !== Response::HTTP_OK) {
                    throw new \RuntimeException('Invald API Key!');
                }
            } catch (RequestException $exception) {
                $this->logger->addError($exception->getMessage());
                throw new \RuntimeException($exception->getMessage());
            }
        }
    }
}